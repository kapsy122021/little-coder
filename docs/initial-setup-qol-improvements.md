# Initial Setup QoL Improvements

Challenges a new developer faces when cloning little-coder and trying to get it up and running via the Docker Compose workflow, organized by category.

---

## 1. Docker Prerequisites Are Assumed, Not Checked

**What:** The entire workflow assumes Docker and Docker Compose are installed and functional.

**Why:** There's no pre-flight check script that validates Docker availability before the user runs `docker compose up`. A developer who hasn't installed Docker, or whose user isn't in the `docker` group, will hit opaque permission errors or "command not found" with no guidance on how to fix it.

**Improvement:** Add a `infra/check-prereqs.sh` that validates Docker, Docker Compose, and user group membership before anything else.

---

## 2. Local LLM Setup Is a Hard Prerequisite With No Guidance

**What:** The Docker stack expects a local LLM server reachable at `host.docker.internal:8000` (default `LLAMACPP_BASE_URL`). The user is responsible for setting this up independently.

**Why:** The README documents llama.cpp, Ollama, and LM Studio as options, but none of them default to port 8000. A developer who follows the README's llama.cpp example (port 8888) or Ollama (port 11434) will get `ECONNREFUSED` from inside the container with no clear path to resolution.

**Improvement:** Add a prominent "Before You Start" section that explicitly calls out the LLM requirement and shows how to point the container at whatever port the user's LLM is actually running on.

---

## 3. Changing the LLM URL Requires Editing Two Files

**What:** The `LLAMACPP_BASE_URL` is hardcoded in `infra/docker-compose.yml` as `http://host.docker.internal:8000/v1`. To change it, the user must edit the compose file directly.

**Why:** The `.env.example` file doesn't expose `LLAMACPP_BASE_URL` as an overridable variable. A developer who runs their LLM on a non-default port (e.g., 8888 for llama.cpp, 11434 for Ollama) must dig into the compose file to find the hardcoded value.

**Improvement:** Move `LLAMACPP_BASE_URL` into `.env.example` so the user can change it in one place without touching the compose file.

---

## 4. `.env` File Must Be Manually Created

**What:** The `.env` file is not committed (it's in `.gitignore`). The user must copy `.env.example` to `.env` and fill in values.

**Why:** `start.sh` checks for `.env` and exits with an error if it's missing. The error message says "Please create .env with OPEN_TERMINAL_API_KEY set" but doesn't mention the `cp` command. A new developer may not know they need to copy the example file.

**Improvement:** Have `start.sh` auto-generate `.env` from `.env.example` if it doesn't exist, or add a one-liner to the README's quick-start section.

---

## 5. OPEN_TERMINAL_API_KEY Generation Is Buried

**What:** The `OPEN_TERMINAL_API_KEY` is required but the generation command (`openssl rand -hex 32`) is buried in comments inside `.env.example`.

**Why:** A developer opening `.env.example` sees `your-generated-random-hex-key-here` and may not notice the comment above it telling them how to generate one. They might paste the placeholder literally, which `start.sh` will reject.

**Improvement:** Generate the key automatically in `start.sh` if the `.env` value is still the placeholder, or add a prominent callout in the quick-start guide.

---

## 6. GitHub PAT Has No Clear Injection Path

**What:** The `.env.example` has a commented-out `GITHUB_TOKEN` line, but there's no mechanism to inject it into the running containers.

**Why:** A developer who wants the agent to clone/push repos will add `GITHUB_TOKEN=ghp_xxx` to `.env`, but the compose file doesn't pass it through to either container. The token sits in `.env` unused.

**Improvement:** Add `GITHUB_TOKEN` to the `environment:` blocks in `docker-compose.yml` so it flows through automatically when the user sets it in `.env`.

---

## 7. No Single "Quick Start" Command

**What:** Getting from clone to "agent running" requires: (1) set up a local LLM, (2) copy `.env.example` to `.env`, (3) generate an API key, (4) run `start.sh`, (5) `docker exec` into the agent container.

**Why:** Each step is documented somewhere in the repo, but no single place walks through the full sequence. A developer has to piece together instructions from the README, `infra/README.md`, and `start.sh` output.

**Improvement:** Add a numbered "5-Minute Quick Start" section to the top-level README that covers the full Docker workflow end-to-end.

---

## 8. Model Mismatch Between Docker and README Examples

**What:** `docker.models.json` declares `qwen3.6:27b` and `qwen3.6:27b-nothink`, but the README and `start.sh` output reference `qwen3.6-35b-a3b` and `qwen3.6:27b`.

**Why:** A developer who copies the README command `little-coder --model llamacpp/qwen3.6-35b-a3b` into the Docker container will get a "model not found" error because that ID isn't registered in `docker.models.json`.

**Improvement:** Align model IDs across `docker.models.json`, `.pi/settings.json`, the README, and `start.sh` output. Or document the discrepancy explicitly.

---

## 9. Resource Limits May Be Too Restrictive

**What:** Both containers are capped at 2g RAM, 2 CPUs, and 256 pids.

**Why:** The agent container runs Node.js + TypeScript extensions + pi's agent loop. 2g may be tight for large context windows (122880 tokens configured for `qwen3.6:27b`). The open-terminal container running long shell commands may hit the pid limit.

**Improvement:** Expose resource limits as `.env` variables so users can tune them without editing the compose file.

---

## 10. No Health Check or Readiness Signal

**What:** `start.sh` runs `docker compose up -d` and immediately prints "Services started successfully!" with no verification that the containers are actually healthy.

**Why:** The agent container may still be building or initializing. A developer who immediately `docker exec` into it may hit a "command not found" or connection error because the container isn't ready yet.

**Improvement:** Add a health check to the compose file and have `start.sh` wait for both containers to report healthy before printing the success message.

---

## 11. Extension System Is Invisible to the End User

**What:** 24 TypeScript extensions auto-load at runtime. The `open-terminal-workspace` extension blocks all built-in tools when `LITTLE_CODER_USE_OPEN_TERMINAL=1`.

**Why:** A developer who runs the agent and tries to use `Read` or `Bash` will see a cryptic error message redirecting them to `OTRead`/`OTBash`. They won't understand why the standard tools are blocked unless they read the extension source.

**Improvement:** Add a startup banner or log message that explains which tools are available and why, especially when the open-terminal workspace mode is active.

---

## 12. No Way to Verify the Stack Is Working Before Running the Agent

**What:** There's no smoke test or connectivity check between the agent container, the open-terminal container, and the host LLM.

**Why:** A developer might spend 20 minutes debugging why the agent won't start, only to discover their LLM server isn't running, or the port is wrong, or the firewall is blocking it.

**Improvement:** Add a `infra/healthcheck.sh` that verifies: (1) both containers are running, (2) the agent can reach open-terminal, (3) the agent can reach the LLM at `LLAMACPP_BASE_URL`.

---

## 13. Docker Build Happens on Every Start (First Time Is Slow)

**What:** The `little-coder` service uses `build: context: ../` which rebuilds the image on every `docker compose up`.

**Why:** The first build installs all npm dependencies and copies the entire repo. On a slow machine or network, this can take several minutes with no progress indication.

**Improvement:** Use `docker compose up -d --build` only when needed, or add a `infra/build.sh` that pre-builds the image with a clear progress message.

---

## 14. No Documentation of the Container-to-Host Network Path

**What:** The agent reaches the host LLM via `host.docker.internal`, which is a Docker-specific DNS name.

**Why:** A developer who changes the compose file or runs Docker in an unusual configuration (e.g., rootless Docker, Podman) may find that `host.docker.internal` doesn't resolve. The `extra_hosts` workaround is documented in a comment but not in any user-facing guide.

**Improvement:** Document the network topology in a diagram and explain how `host.docker.internal` works, including alternatives for non-standard Docker setups.
