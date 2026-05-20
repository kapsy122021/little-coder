# little-coder

**A coding agent tuned for small local models, built on top of [pi](https://pi.dev).**

The recommended setup is the Docker Compose stack in `infra/` — it bundles the agent with a sandboxed shell environment and is the fastest path to a working install. See [Local model setup](#local-model-setup-optional) for inference options.

---

## Container setup (Docker — recommended for new developers)

The `infra/` directory ships a Docker Compose stack that bundles the little-coder agent together with [open-terminal](https://github.com/open-webui/open-terminal) — a sandboxed shell environment the agent operates inside. This is the recommended path for a clean, reproducible setup that doesn't touch your host system.

### Requirements

| Requirement      | Minimum version                  | Notes                                                                                          |
| ---------------- | -------------------------------- | ---------------------------------------------------------------------------------------------- |
| Docker Engine    | 24+                              | Or Docker Desktop 4.x on macOS/Windows                                                         |
| Docker Compose   | v2 (the `docker compose` plugin) | **Not** the legacy `docker-compose` binary                                                     |
| Node.js          | 22.19+                           | Only needed if you run `little-coder` outside Docker                                           |
| Git              | any                              | For cloning this repo                                                                          |
| Free RAM         | 2 GB                             | Each container is capped at 2 GB; 4 GB total recommended                                       |
| Inference server | running                          | A local `llama-server` or cloud API key — see [Local model setup](#local-model-setup-optional) |

> **Windows users.** Run all `bash infra/*.sh` commands inside WSL 2 or Git Bash. Docker Desktop with the WSL 2 backend is the easiest path.

### 1. Clone and enter the repo

```bash
git clone https://github.com/itayinbarr/little-coder.git
cd little-coder
```

### 2. Configure the API key

```bash
cp infra/.env.example infra/.env
```

Open `infra/.env` and replace the placeholder with a freshly generated secret:

```bash
# Linux / macOS / WSL
openssl rand -hex 32

# Windows PowerShell (no WSL)
$bytes = New-Object Byte[] 32
(New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes)
-join ($bytes | ForEach-Object { $_.ToString("x2") })
```

Paste the output into `infra/.env`:

```env
OPEN_TERMINAL_API_KEY=<your-generated-key>
LLAMACPP_API_KEY=noop   # leave as-is unless your proxy requires a real token
```

> `infra/.env` is `.gitignore`-protected. Never commit it.

### 3. Configure git credentials

The agent runs `git clone / push / pull` inside the open-terminal container. Credentials are bind-mounted from the host at `infra/git/credentials` → `/home/user/.git-credentials` inside the container. **They survive both soft and hard wipes** because the file lives on the host.

```bash
cp infra/git/credentials.example infra/git/credentials
```

Edit `infra/git/credentials` and add one line per repo (or one line per token scope):

```
https://x-access-token:<YOUR_GITHUB_PAT>@github.com/<owner>/<repo>
```

A single fine-grained PAT that covers all your repos can be written as:

```
https://x-access-token:<YOUR_GITHUB_PAT>@github.com
```

Git picks the most specific matching entry automatically — no per-launch flags needed. To add, change, or revoke a token, edit `infra/git/credentials` on the host. The change takes effect immediately; no container restart required.

> **Security**: `infra/git/credentials` is listed in `.gitignore`. Never commit it. If you accidentally commit a PAT, revoke it immediately on GitHub and generate a new one.

To update your git identity (name / email shown in commits), edit `infra/git/gitconfig`:

```ini
[user]
    name  = Your Name
    email = you@example.com
```

### 4. Start the stack

```bash
bash infra/start.sh
```

`start.sh` validates `.env`, then runs `docker compose up -d` to bring up both containers on the `little-coder-net` bridge network.

### 5. Launch the agent

```bash
# Interactive session (most common)
docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b

# Non-thinking variant (faster, lower quality)
docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b-nothink

# Pass a one-shot task directly
docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b "Explain this codebase"
```

The agent's `Read` / `Write` / `Edit` / `Bash` tools execute inside the open-terminal container — your host filesystem is not touched.

### 6. Clone and work with your project repos

Once the agent is running, tell it to clone any repo your credentials cover. The `infra/git/credentials` file is already bind-mounted inside the terminal container, so no extra auth flags are needed — git picks the right token automatically.

**Example chat prompts:**

```
Clone https://github.com/<owner>/<repo>.git into ~/projects and give me an overview of the codebase.
```

```
Clone https://github.com/<owner>/<repo>.git, create a branch called feature/my-change, then implement <task>.
```

```
Clone https://github.com/<owner>/<repo>.git and fix the failing tests in src/utils/.
```

```
Clone https://github.com/<owner>/<repo>.git, make the changes needed to close issue #42, commit, and push the branch.
```

The agent clones into `/home/user/projects/` inside the open-terminal container. When done, run a wipe to clean up before the next task.

> **Adding a new token mid-session.** Edit `infra/git/credentials` on the host at any time — the file is bind-mounted, so the change is live immediately with no container restart.

### Useful commands

| Command                                              | What it does                                                                |
| ---------------------------------------------------- | --------------------------------------------------------------------------- |
| `bash infra/start.sh`                                | Build images (first time) and start both containers                         |
| `bash infra/stop.sh`                                 | Gracefully stop both containers                                             |
| `bash infra/status.sh`                               | Show running containers and exposed ports                                   |
| `bash infra/verify-security.sh`                      | Audit port bindings, resource limits, network isolation                     |
| `bash infra/wipe-soft.sh`                            | Clear `/home/user/projects` inside open-terminal; tools and caches are kept |
| `bash infra/wipe-hard.sh`                            | Destroy and rebuild both containers from scratch                            |
| `docker logs -f little-coder`                        | Stream agent logs                                                           |
| `docker logs -f open-terminal`                       | Stream terminal logs                                                        |
| `docker compose -f infra/docker-compose.yml logs -f` | Stream logs from both services                                              |
| `docker exec -it open-terminal bash`                 | Drop into a shell inside the terminal container                             |
| `little-coder --list-models`                         | List every registered model (run from inside the container or on the host)  |

**llama-swap model management** (runs against the host inference proxy at `http://127.0.0.1:8000`):

### UNLOAD - first cd to the llama-swap directory

cd C:\Users\Kaps\Documents\projects_git\little-coder

| Command                                                            | What it does                            |
| ------------------------------------------------------------------ | --------------------------------------- |
| `curl http://127.0.0.1:8000/running`                               | List models currently loaded in memory  |
| `curl -X POST http://127.0.0.1:8000/api/models/unload`             | Unload all running models and free VRAM |
| `curl -X POST http://127.0.0.1:8000/api/models/unload/qwen3.6:27b` | Unload a specific model by ID           |
| `curl http://127.0.0.1:8000/logs`                                  | Dump buffered proxy + upstream logs     |
| `curl -Ns http://127.0.0.1:8000/logs/stream`                       | Stream live logs from all processes     |

### Wipe strategies

After finishing a project, choose a wipe level:

**Soft wipe** — clears project files, keeps installed tools and caches:

```bash
bash infra/wipe-soft.sh
```

Use between low-sensitivity tasks where rebuilding the tool environment would be slow.

**Hard wipe** — destroys and rebuilds containers entirely:

```bash
bash infra/wipe-hard.sh
```

Use when you want a completely clean slate or need to pick up Dockerfile changes. Note: `infra/git/credentials` and `infra/git/gitconfig` survive both wipes because they are bind-mounted from the host.

---

## Local model setup (optional)

Skip this section if you're using a cloud model.

**Option A — llama.cpp** (fastest for local; supports Qwen3.6-35B-A3B MoE):

```bash
# One-time: build llama.cpp with CUDA (sm_XXX = your GPU arch; Blackwell = 120)
git clone https://github.com/ggml-org/llama.cpp && cd llama.cpp
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=120 -DLLAMA_CURL=ON
cmake --build build --config Release -j

# Fetch the model GGUF and the matching vision projector.
# The mmproj (~900 MB) is what lets the model see attached screenshots.
pip install -U "huggingface_hub[cli]"
hf download unsloth/Qwen3.6-35B-A3B-GGUF Qwen3.6-35B-A3B-UD-Q4_K_M.gguf --local-dir ~/models
hf download unsloth/Qwen3.6-35B-A3B-GGUF mmproj-F16.gguf            --local-dir ~/models

# Serve it (MoE trick: experts in RAM, attention on GPU → 22 GB model on 8 GB VRAM)
build/bin/llama-server -m ~/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
   --mmproj ~/models/mmproj-F16.gguf \
   --host 127.0.0.1 --port 8888 --jinja \
   -c 16384 -ngl 99 --n-cpu-moe 999 --flash-attn on
```

If you only need text and want to skip the projector download, drop the second `hf download` line and the `--mmproj` flag — little-coder still works text-only, but the TUI's image attachment will be rejected by the server with a 4xx.

**Option B — Ollama** (simpler, but slower on MoE):

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen3.5        # 9.7B — the paper's model
# or: ollama pull qwen3.6-35b-a3b
```

**Option C — LM Studio** (GUI; OpenAI-compatible server on port 1234):

1. Install [LM Studio](https://lmstudio.ai/) and download a model (e.g. Qwen3.6 35B A3B GGUF).
2. Open the **Developer** / **Local Server** tab, load the model, and click **Start Server** (default `http://127.0.0.1:1234`).
3. Run little-coder:
   ```bash
   export LMSTUDIO_API_KEY=noop
   little-coder --model lmstudio/local-model
   ```
   The shipped `lmstudio/local-model` id routes to whatever model LM Studio currently has loaded — no extra config needed for the single-model case. If you serve on a non-default port, set `LMSTUDIO_BASE_URL=http://127.0.0.1:<port>/v1`. To target a specific model when you have several loaded, add an entry to `~/.config/little-coder/models.json` (see **Configuring models** below).

---

## Configuring models

The shipped model list lives in **`models.json`** at the package root. The `llama-cpp-provider` extension reads it at startup and registers each provider via pi's `registerProvider()`. Editing this file in your global install **does** take effect — but it's overwritten on `npm install -g little-coder@latest`, so for anything you want to keep, use a user override file instead.

User override resolution (first match wins):

1. `$LITTLE_CODER_MODELS_FILE` — explicit path, useful for ad-hoc tests.
2. `$XDG_CONFIG_HOME/little-coder/models.json`
3. `~/.config/little-coder/models.json`

Merge semantics: each top-level provider key in your override file **fully replaces** the same key in the shipped `models.json`. Providers only in your file are added; providers only in the shipped file are kept. (We don't deep-merge per-model fields — you redeclare the whole provider entry, which avoids "your override silently inherited new fields from a future package release" surprises.)

Example — switch the llama.cpp port and bump `qwen3.6-35b-a3b` to a 150K context, leave ollama untouched:

```json
{
  "providers": {
    "llamacpp": {
      "api": "openai-completions",
      "baseUrl": "http://127.0.0.1:1234/v1",
      "apiKey": "LLAMACPP_API_KEY",
      "models": [
        {
          "id": "qwen3.6-35b-a3b",
          "name": "Qwen3.6-35B-A3B (local llama.cpp, 150K)",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 150000,
          "maxTokens": 4096,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

Then verify with `little-coder --list-models` — you should see your overridden entry.

`LLAMACPP_BASE_URL`, `OLLAMA_BASE_URL`, and `LMSTUDIO_BASE_URL` env vars still beat both files for those three providers.

`.pi/settings.json` is a separate concern: it controls per-model **profiles** (context_limit, thinking_budget, temperature, benchmark_overrides) referenced by the `<provider>/<id>` key. Profiles don't register or describe models — they only tune how little-coder runs against models that are already registered.

---

## Permissions

little-coder gates `Bash` tool calls against a built-in safe-prefix whitelist (`ls`, `cat`, `head`, `tail`, `git log/status/diff`, `find`, `grep`, `cp`, `mv`, `mkdir`, `touch`, etc.) before pi's own confirmation flow ever sees them. `rm` and `sudo` are intentionally not on the list — add them via `LITTLE_CODER_BASH_ALLOW` per deployment if you really need them.

Two env vars control the gate:

| Env var                        | Values                                       | Effect                                                                                                                                                                                                               |
| ------------------------------ | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `LITTLE_CODER_PERMISSION_MODE` | `auto` _(default)_ / `accept-all` / `manual` | `auto`: block any bash command not on the whitelist. `accept-all`: skip the gate entirely, every bash call passes (the benchmark runner sets this). `manual`: same as `auto` but with a different rejection message. |
| `LITTLE_CODER_BASH_ALLOW`      | comma-separated prefixes                     | Extra allow-prefixes merged with the built-in list. **Trailing whitespace is meaningful**: `"make "` allows `make test` but not `makefoo`; `"make"` allows both.                                                     |

Examples:

```bash
# Add 'make' (with word-boundary) and 'docker compose ps' on top of the defaults
export LITTLE_CODER_BASH_ALLOW="make ,docker compose ps"

# Skip the gate entirely (use this only inside controlled environments)
export LITTLE_CODER_PERMISSION_MODE=accept-all
```

Write/Edit confirmations are pi's responsibility; little-coder doesn't intercept those.

---

## Troubleshooting

**Containers don't start / `.env` error** — make sure you ran `cp infra/.env.example infra/.env` and replaced the placeholder key. `start.sh` exits with an error if the placeholder is still present.

**`ECONNREFUSED` to the inference server** — the llama-server (or Ollama/LM Studio) isn't running, or the `LLAMACPP_BASE_URL` points at the wrong host. Inside Docker, use `host.docker.internal` instead of `127.0.0.1` to reach processes on the host (the compose file sets this automatically via `extra_hosts`).

**`git clone` fails inside the agent** — check that `infra/git/credentials` exists and contains a valid PAT entry for the repo's host. The file is bind-mounted read-only; any edit on the host is immediately visible inside the container.

**No API key env var warning** — pi requires _some_ value even for local providers. Set `LLAMACPP_API_KEY=noop` in `infra/.env` (the template already includes it).

**Extension load failures on startup** — run `docker exec -it little-coder little-coder --list-models --verbose`; extension errors surface there. If the image looks corrupt, run `bash infra/wipe-hard.sh` to rebuild from scratch.

**Node version too old (outside Docker)** — little-coder requires Node ≥ 22.19.0. Check with `node --version`; upgrade with `nvm install 22 && nvm use 22`.

---

## Architecture

````
little-coder/
├── .pi/
│   ├── settings.json               # per-model profiles + benchmark_overrides (terminal_bench, gaia)
│   └── extensions/                 # 21 TypeScript extensions, auto-discovered by pi
│       ├── branding/               # little-coder startup header + terminal title (replaces pi's built-in)
│       ├── llama-cpp-provider/     # data-driven provider registration from models.json — ships llamacpp, ollama, lmstudio (+ user override file)
│       ├── write-guard/            # Write refuses on existing files; rewrites root-bare /foo.md paths to cwd
│       ├── extra-tools/            # glob, webfetch, websearch (pi ships grep/find)
│       ├── skill-inject/           # per-turn tool-skill selection (error > recency > intent)
│       ├── knowledge-inject/       # algorithm cheat-sheet scoring (word=1.0, bigram=2.0, threshold=2.0)
│       ├── output-parser/          # repair malformed ```tool, <tool_call>, bare JSON
│       ├── quality-monitor/        # empty / hallucinated / loop detection + correction follow-up
│       ├── thinking-budget/        # cap thinking tokens per turn, retry with thinking off
│       ├── permission-gate/        # bash whitelist (ls, cat, git log/status/diff, etc.)
│       ├── checkpoint/             # snapshot files before Write/Edit
│       ├── tool-gating/            # enforces _allowed_tools at exec + schema levels
│       ├── turn-cap/               # max_turns abort (Polyglot unbounded, TB 40, GAIA 30)
│       ├── benchmark-profiles/     # reads settings.json → systemPromptOptions + sets temperature
│       ├── shell-session/          # ShellSession[Cwd|Reset] — tmux-proxy + subprocess backends
│       ├── browser/                # Playwright BrowserNavigate/Click/Type/Scroll/Extract/Back/History
│       ├── evidence/               # EvidenceAdd/Get/List — per-session store, 1 KB snippet cap
│       └── evidence-compact/       # preserves evidence across pi's auto-compaction
├── skills/                         # 30 markdown files the extensions inject on demand
│   ├── tools/*.md                  #   14 tool-usage cards
│   ├── knowledge/*.md              #   13 algorithm cheat sheets
│   └── protocols/*.md              #    3 research/cite/decomposition workflows
├── benchmarks/
│   ├── rpc_client.py               # PiRpc — spawns `pi --mode rpc`, demuxes events + UI requests
│   ├── aider_polyglot.py           # Polyglot driver with per-language transforms
│   ├── tb_adapter/                 # Terminal-Bench 1.0 BaseAgent (tmux-proxy)
│   ├── harbor_adapter/             # Terminal-Bench 2.0 BaseAgent (async env.exec proxy)
│   ├── tb_pilot.sh / harbor_pilot.sh
│   ├── tb_status.sh / harbor_status.sh
│   └── test_rpc_client.py
├── AGENTS.md                       # project system prompt (pi discovers it automatically)
├── models.json                     # canonical provider registration (loaded by llama-cpp-provider; user override at $XDG_CONFIG_HOME/little-coder/models.json)
└── docs/
    ├── benchmark-*.md              # per-benchmark narratives
    └── architecture.md             # v0.0.5-era Python architecture (historical)
````

**Key invariant.** pi is a minimal base by design. Every little-coder mechanism ships as a pi extension that hooks pi's lifecycle events (`before_agent_start`, `context`, `before_provider_request`, `tool_call`, `tool_result`, `turn_end`, `session_compact`). Extensions are independent and can be enabled/disabled per deployment via `.pi/settings.json`. If you don't want one, delete its directory or disable it in settings; if you want to add another, drop it next to the existing ones.

---

## License

Apache 2.0 — see [LICENSE](LICENSE) for details. NOTICE tracks upstream attribution.
