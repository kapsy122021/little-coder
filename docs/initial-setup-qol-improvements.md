# Initial Setup QoL Improvements

Challenges a new developer faces when cloning little-coder and trying to get it up and running, organized by category.

---

## 1. Node.js Version Requirement

**What:** Node.js ≥ 22.19.0 is required (hard minimum, enforced at install time).

**Why:** The bundled dependency `@earendil-works/pi-coding-agent` v0.75+ requires it. The install script checks the version and exits with an error if too old. Many developers have older LTS versions (e.g., 18.x or 20.x) and won't realize the constraint until install fails.

**Fix:** `nvm install 22 && nvm use 22` — but this isn't obvious from the error message alone.

---

## 2. npm Global Install Permissions

**What:** `npm install -g little-coder` may fail with `EACCES` if the npm global prefix isn't user-writable.

**Why:** The install script and README both default to global install. On macOS (Homebrew Node) and many Linux distros, the global prefix is `/usr/local` or `/opt/homebrew`, which requires `sudo`. The README mentions this in Troubleshooting but not inline in the install section.

**Fix:** `sudo npm install -g little-coder` or configure a user-writable npm prefix — but the developer has to discover this after the first failure.

---

## 3. bun Users Still Need Node

**What:** Even if you install via `bun add -g little-coder`, the launcher script has `#!/usr/bin/env node` — Node 22.19+ must still be on PATH at runtime.

**Why:** The README mentions this in a footnote, but it's easy to miss. A developer who installed bun specifically to avoid Node will be confused when the binary won't start.

---

## 4. Choosing a Model Provider (Three Paths, Each Complex)

**What:** The developer must pick a model provider and set it up before little-coder can do anything useful. There are three options, each with its own friction:

### Option A — llama.cpp (Recommended but Hardest)

- Requires building from source with CMake + CUDA
- Must know your GPU architecture (`sm_XXX` / `DCMAKE_CUDA_ARCHITECTURES`)
- Must download a ~22 GB GGUF model + a ~900 MB vision projector
- Requires `huggingface_hub[cli]` (pip install)
- The MoE serving trick (`--n-cpu-moe 999 -ngl 99`) is non-obvious and undocumented outside the README
- If you skip the vision projector, image attachment silently 4xxs

### Option B — Ollama (Simpler but Slower on MoE)

- One-line install + `ollama pull`, but the README says it's "slower on MoE" without quantifying how much slower
- The model IDs in `models.json` don't match Ollama's naming (`qwen3.5` vs `qwen3.6-35b-a3b`)

### Option C — LM Studio (GUI, Easiest)

- Requires downloading the GUI app, loading a model, starting the server manually
- The `lmstudio/local-model` id is a magic routing key that may confuse developers

---

## 5. API Key Environment Variables (Even for Local Models)

**What:** Local providers (llama.cpp, Ollama, LM Studio) require a dummy API key env var (`LLAMACPP_API_KEY=noop`).

**Why:** pi's provider abstraction expects *some* key value even though local servers ignore it. Without it, you get a confusing "no API key" warning. This is counterintuitive — why does a local server need an API key?

---

## 6. Docker Deployment Complexity

**What:** The `infra/` directory provides a Docker Compose stack that runs the agent and an "open-terminal" workspace container as separate services.

**Why it's complex:**

- Requires Docker + Docker Compose installed
- Requires generating an `OPEN_TERMINAL_API_KEY` (hex secret)
- The `.env` file must be created from `.env.example` (not done automatically)
- `start.sh` validates the `.env` and will refuse to start if the key is still the placeholder
- The agent container depends on `host.docker.internal:8000` resolving to a llama-ingress-proxy on the host — this is an external dependency not documented as a prerequisite
- `host.docker.internal` requires `extra_hosts` on Linux Docker (handled in compose, but easy to break if customizing)
- Resource limits (2g RAM, 2 CPUs, 256 pids) may be too low for some workloads
- The open-terminal container image (`ghcr.io/open-webui/open-terminal:slim`) must be pulled

---

## 7. Model Configuration Confusion

**What:** There are three layers of model configuration that interact:

1. `models.json` — shipped provider registration (what models exist)
2. `.pi/settings.json` — per-model profiles (context limits, thinking budget, temperature)
3. `docker.models.json` — Docker-specific model list (only `qwen3.6:27b` variants)

**Why it's confusing:**

- The shipped `models.json` only declares `llamacpp` with `qwen3.6:27b` models, but the README examples use `qwen3.6-35b-a3b` — a model ID that exists in `.pi/settings.json` profiles but **not** in `models.json`
- User override files (`~/.config/little-coder/models.json`) use per-provider replace semantics, not deep merge — easy to accidentally wipe out providers
- `LLAMACPP_BASE_URL` env var overrides both files, but the default port differs between `models.json` (8000) and the README examples (8888)

---

## 8. Extension System Opacity

**What:** little-coder ships 24 TypeScript extensions under `.pi/extensions/` that hook into pi's lifecycle events.

**Why it's a challenge:**

- Extensions are auto-discovered by pi — a developer won't know what's running unless they read the source
- The `open-terminal-workspace` extension blocks all built-in tools (Read/Write/Edit/Bash) when `LITTLE_CODER_USE_OPEN_TERMINAL=1` — this is invisible to the developer until they see the error message
- Extensions can be disabled via `.pi/settings.json`, but the format isn't documented
- TypeScript extensions are not compiled/bundled — they're loaded directly by pi, which means TypeScript errors surface at runtime

---

## 9. Benchmark Harness Dependencies

**What:** Running benchmarks requires a Python environment with specific dependencies that aren't declared in a `requirements.txt`.

**Why it's a challenge:**

- `benchmarks/rpc_client.py` spawns `pi --mode rpc` as a subprocess — requires `npm install` in the repo root first
- `benchmarks/aider_polyglot.py` expects a polyglot benchmark checkout at `~/Documents/polyglot-benchmark`
- `benchmarks/tb_pilot.sh` expects a terminal-bench checkout at `~/Documents/terminal-bench`
- `benchmarks/harbor_pilot.sh` requires `harbor` installed via `uv tool install harbor`
- Docker access is required for Terminal-Bench runs (user must be in `docker` group or use `sg docker`)
- No `requirements.txt` or `pyproject.toml` for Python dependencies — they're assumed to be installed

---

## 10. Permission Gate Configuration

**What:** The `permission-gate` extension blocks bash commands not on a whitelist. `rm` and `sudo` are intentionally excluded.

**Why it's a challenge:**

- A developer trying to do real work will hit unexpected command rejections
- The `LITTLE_CODER_BASH_ALLOW` env var and trailing-whitespace semantics (`"make "` vs `"make"`) are subtle
- The `LITTLE_CODER_PERMISSION_MODE` env var (`auto` / `accept-all` / `manual`) isn't mentioned until deep in the README
- Benchmark runners set `accept-all`, but interactive use defaults to `auto`

---

## 11. LAN / Remote Inference Setup

**What:** Serving the model on a different machine requires firewall configuration, `host.docker.internal` resolution, and provider-specific binding changes.

**Why it's a challenge:**

- `ufw` / `firewalld` default-deny policies silently drop connections (no RST, just hangs)
- Each provider has different flags for LAN binding (`--host 0.0.0.0`, `OLLAMA_HOST`, LM Studio GUI toggle)
- The README documents this but it's buried deep in the "Local model setup" section

---

## 12. No Quick Start for "Just Try It"

**What:** There's no single command that gets a developer from zero to "the agent is working" without already having a model server running.

**Why it's a challenge:**

- The install step and the model setup step are separate, and the model setup is the hard part
- A developer who just wants to test the TUI will install little-coder, run it, and immediately get `ECONNREFUSED` because no model is running
- There's no built-in demo mode or fallback model
