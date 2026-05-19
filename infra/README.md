# Little-Coder Unified Deployment Guide

This directory implements the unified Docker Compose stack that combines **open-terminal** (execution environment) and **little-coder** (agent runtime) as a single cohesive system called **Little-Coder**.

## Architecture

```
┌──────────────────────────────────────────────────┐
│        Little-Coder Unified Parent              │
│                                                  │
│  ┌─────────────────────────────────────────┐   │
│  │   little-coder-net (shared bridge)      │   │
│  │                                         │   │
│  │  ┌──────────────────┐  ┌──────────────┐│   │
│  │  │ little-coder-    │  │ little-coder-││   │
│  │  │ agent            │◄─┤ terminal     ││   │
│  │  │                  │  │              ││   │
│  │  │ Node.js process  │  │ Uvicorn server  │   │
│  │  │ (port 3000)      │  │ (port 8000)  ││   │
│  │  └──────────────────┘  └──────────────┘│   │
│  │           ▲                    │        │   │
│  │           └────────────────────┘        │   │
│  │                                         │   │
│  │    http://little-coder-terminal:8000   │   │
│  │    (internal service discovery)        │   │
│  └─────────────────────────────────────────┘   │
│                    │                             │
│                    │ Exposed ports              │
│                    └─→ 127.0.0.1:8001           │
│                       (terminal external)       │
└──────────────────────────────────────────────────┘
```

## Unified Deployment Model

**Both services are managed as a single unit under the parent name "Little-Coder":**

- **Primary compose file**: `docker-compose.yml`
- **Network**: `little-coder-net` (shared bridge network)
- **Containers**:
  - `little-coder-agent` — Main coding agent (builds from `../Dockerfile`)
  - `little-coder-terminal` — Terminal execution environment
- **Startup order**: Agent depends on terminal (automatic with `depends_on`)
- **Service discovery**: Agent can reach terminal at `http://little-coder-terminal:8000`

## Security Posture

All configurations apply **hardening by default**:

- ✅ **Shared secure network** — Containers can communicate safely
- ✅ **Loopback-only external port** — Port 8001 bound to 127.0.0.1 only
- ✅ **Resource limits** — CPU, memory, and process counts capped
- ✅ **No Docker socket exposure** — Containers cannot manage host/each other
- ✅ **API key protection** — OPEN_TERMINAL_API_KEY required for terminal access

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | **Primary** unified stack (both services) |
| `.env` | Environment secrets (API key) |
| `.env.example` | Template for .env setup |
| `start.sh` | Launch with validation |
| `stop.sh` | Graceful shutdown |
| `status.sh` | Show running services |
| `wipe-soft.sh` | Clear terminal workspace |
| `wipe-hard.sh` | Full reset |
| `verify-security.sh` | Audit security controls |
| `open-terminal-isolated.compose.yml` | Legacy (for reference) |
| `open-terminal-isolated-persistent.compose.yml` | Legacy (for reference) |

## Quick Start

### 1. Prerequisites

- Docker and Docker Compose installed
- Port 8001 available (or modify the binding in `docker-compose.yml`)
- API key configured (see below)

### 2. Configure Secrets

API key is already set in `.env`:

```env
OPEN_TERMINAL_API_KEY=a6f66141707c0462ae01d9b0c2ef17cf4e575d7b3d2aac3b87c0c919e846e66d
```

To generate a new key:

```bash
openssl rand -hex 32  # On Linux/Mac
# Or Windows PowerShell:
$bytes = New-Object Byte[] 32; (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes); -join ($bytes | ForEach-Object { $_.ToString("x2") })
```

### 3. Start the Stack

```bash
bash infra/start.sh
```

This will:
- Validate `.env` configuration
- Build `little-coder-agent` image (first time only)
- Pull `open-terminal:slim` image
- Create `little-coder-net` bridge network
- Start both containers

### 4. Verify Startup

```bash
bash infra/status.sh
```

Expected output:

```
little-coder-agent    (Running)  port 3000 internal
little-coder-terminal (Running)  port 127.0.0.1:8001 → 8000
Network: little-coder-net
```

### 5. Monitor Logs

```bash
# Agent logs
docker logs -f little-coder-agent

# Terminal logs
docker logs -f little-coder-terminal

# Both
docker compose -f infra/docker-compose.yml logs -f
```

## Usage

### Running a Coding Task

Inside the agent, you can invoke the terminal:

```bash
# From little-coder-agent container
curl http://little-coder-terminal:8000/api/status

# Or via the agent's scripting
node bin/little-coder.mjs --terminal-url http://little-coder-terminal:8000
```

### External Terminal Access

The terminal is accessible from the host for debugging:

```bash
curl http://127.0.0.1:8001/api/status
```

But this is not the primary integration point—the agent accesses the terminal internally.

### Project Workflow

**Inside the terminal or agent:**

```bash
# Prepare workspace
mkdir -p ~/projects
cd ~/projects

# Clone target repo
git clone https://github.com/ORG/REPO.git
cd REPO

# Create feature branch
git checkout -b agent/task-$(date +%Y%m%d-%H%M%S)

# Make changes (agent drives this)
# ...

# Commit and push
git add -A
git commit -m "agent: implement task"
git push origin HEAD
```

## Wipe Strategies

After each project, choose a wipe strategy based on sensitivity:

### Soft Wipe (Fast)

Clears project files but preserves installed tools and shell history:

```bash
bash infra/wipe-soft.sh
```

Use when:
- You're running multiple low-sensitivity projects
- Performance is critical
- Tools/caches are expensive to rebuild

**Result**: `~/projects/*` cleared; everything else preserved.

### Hard Wipe (Cleanest)

Destroys containers and removes all persistent data:

```bash
bash infra/wipe-hard.sh
```

Use when:
- Working with sensitive data
- Strict project isolation required
- Starting fresh for each task

**Result**: Fresh containers, empty workspace, clean shell history.

## Operational Commands

### Start

```bash
bash infra/start.sh
```

### Check Status

```bash
bash infra/status.sh
```

### View Logs

```bash
docker logs -f little-coder-agent
docker logs -f little-coder-terminal
```

### Stop

```bash
bash infra/stop.sh
```

### Soft Wipe (Clear Projects)

```bash
bash infra/wipe-soft.sh
```

### Hard Wipe (Full Reset)

```bash
bash infra/wipe-hard.sh
```

### Verify Security

```bash
bash infra/verify-security.sh
```

### Full Docker Inspect

```bash
docker compose -f infra/docker-compose.yml ps -a
docker network ls | grep little-coder
docker inspect little-coder-net
```

## Environment Variables

**Set in `.env`:**

| Variable | Purpose | Example |
|----------|---------|---------|
| `OPEN_TERMINAL_API_KEY` | Terminal authentication | Hex string (32 bytes) |

**Available inside containers:**

- `OPEN_TERMINAL_URL` (agent only) — `http://little-coder-terminal:8000`
- `OPEN_TERMINAL_API_KEY` (both) — Shared API key for terminal auth

To add more variables:

1. Update `.env`
2. Reference them in `docker-compose.yml` under `environment:`
3. Restart: `bash infra/stop.sh && bash infra/start.sh`

## Network Communication

**Inside the container network:**

- Agent → Terminal: `http://little-coder-terminal:8000`
- Agent ← Terminal: Not applicable (terminal is passive)
- External → Terminal: `http://127.0.0.1:8001` (debugging only)

**DNS:**

Docker's embedded DNS makes containers discoverable by name:

```bash
# From agent or terminal
curl http://little-coder-terminal:8000
# Resolves to 172.20.0.X (internal IP)
```

## Token & Credential Guidance

### GitHub Access

For the agent to clone/push repositories:

1. **Generate a fine-grained GitHub token**:
   - [Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens?type=beta)
   - Scoped to specific repositories
   - Permissions: `Contents: read/write`, `Pull Requests: write`

2. **Inject into agent at startup** (update `docker-compose.yml`):

   ```yaml
   services:
     little-coder-agent:
       environment:
         GITHUB_TOKEN: ${GITHUB_TOKEN}
   ```

3. **Set in `.env`**:

   ```env
   GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

4. **Rotate regularly** (monthly recommended)

### Inside the Agent

```bash
# Example: Authenticate with gh CLI
export GITHUB_TOKEN=$(cat /run/secrets/github_token)
gh auth login
```

**Never hardcode tokens in code or commit to Git.**

## Troubleshooting

### Containers won't start

**Check `.env`:**

```bash
cat infra/.env
```

Ensure `OPEN_TERMINAL_API_KEY` is not the placeholder value.

**Check logs:**

```bash
docker compose -f infra/docker-compose.yml logs
```

Common causes:
- API key is placeholder
- Port 8001 already in use
- Agent image build failed

### Agent can't reach terminal

**Inside agent container, test connectivity:**

```bash
docker exec little-coder-agent curl http://little-coder-terminal:8000/api/status
```

If this fails:
- Check network: `docker network inspect little-coder-net`
- Verify terminal is running: `docker ps | grep little-coder-terminal`
- Check terminal logs: `docker logs little-coder-terminal`

### Port 8001 already in use

Find what's using it:

```bash
# On Linux
lsof -i :8001

# On Windows PowerShell
Get-NetTCPConnection -LocalPort 8001
```

Either stop the conflicting service or change the port in `docker-compose.yml`:

```yaml
ports:
  - "127.0.0.1:8002:8000"  # Use 8002 instead
```

### Build fails

Ensure the Dockerfile exists and is valid:

```bash
cd infra
docker build -f ../Dockerfile -t little-coder:local ..
```

If it fails, check:
- `npm install` can complete
- All source files are present
- No circular dependencies

## Verification Checklist

After startup, run:

```bash
bash infra/verify-security.sh
```

Confirms:
- ✓ Both containers running
- ✓ Shared network active
- ✓ Resource limits applied
- ✓ Port binding correct

## Architecture Decisions

### Why a single parent?

- **Unified lifecycle**: Both services start/stop together
- **Service discovery**: Agent can reach terminal by name
- **Simplified operations**: One compose file, one network
- **Shared environment**: Both have access to API key and configuration

### Why separate containers?

- **Process isolation**: Each service has own PID, filesystem view
- **Resource control**: Limits applied per-container
- **Crash isolation**: Terminal failure doesn't kill agent
- **Scaling**: Can adjust resource limits independently

### Why loopback-only port?

- **Host security**: Only local processes can access terminal
- **Network isolation**: Terminal not exposed to LAN
- **Debugging**: Still accessible for troubleshooting

## Advanced Configuration

### Persistent Volumes

To keep `/home/user` across restarts:

```yaml
services:
  little-coder-terminal:
    volumes:
      - terminal-home:/home/user

volumes:
  terminal-home:
```

Then rebuild: `docker compose -f infra/docker-compose.yml up -d`

### Custom Resources

Adjust limits for your hardware:

```yaml
services:
  little-coder-agent:
    mem_limit: 4g      # 4GB
    cpus: 4             # 4 cores
    pids_limit: 512     # 512 processes
```

### Development Mode

Mount source for hot reload:

```yaml
services:
  little-coder-agent:
    volumes:
      - ../:/app       # Mount source at /app
    command: npm run dev  # Instead of default
```

## References

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Open Terminal GitHub](https://github.com/open-webui/open-terminal)
- [Little-Coder Repository](../)
- [Original Architecture Plan](../docs/plans/openterminal-workspace.md)
