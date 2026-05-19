# Isolated Open Terminal Deployment Guide

This directory implements the security hardened, isolated Docker Compose stack for open-terminal and little-coder as described in [docs/plans/openterminal-workspace.md](../docs/plans/openterminal-workspace.md).

## Security Default Posture

All configurations apply **security by default**:

- ✅ **No Docker socket exposure** — Containers cannot manage each other or the host
- ✅ **Read-only root filesystems** — Immutable execution environment
- ✅ **All capabilities dropped** (`cap_drop: ["ALL"]`) — Minimal privilege
- ✅ **Ephemeral workspace** — Default tmpfs (no persistent state in secure mode)
- ✅ **Isolated networks** — `ot-net` and `lc-net` keep containers separated
- ✅ **Loopback-only binding** — Open Terminal port 8001 only accessible locally (127.0.0.1)
- ✅ **Resource limits** — CPU, memory, and process counts capped
- ✅ **no-new-privileges** — Prevents privilege escalation via setuid binaries

## Files

| File                                            | Purpose                                                           |
| ----------------------------------------------- | ----------------------------------------------------------------- |
| `open-terminal-isolated.compose.yml`            | Default ephemeral stack (security-first)                          |
| `open-terminal-isolated-persistent.compose.yml` | Persistent variant (if you need `/home/user` to survive restarts) |
| `.env`                                          | Environment variables (API key, secrets)                          |
| `start.sh`                                      | Launch the stack with validation                                  |
| `stop.sh`                                       | Shut down the stack cleanly                                       |
| `status.sh`                                     | Show running containers, networks, volumes                        |
| `wipe-soft.sh`                                  | Clear project workspace (keeps tools/caches)                      |
| `wipe-hard.sh`                                  | Full reset (destroy and recreate)                                 |
| `verify-security.sh`                            | Audit security configuration                                      |

## Quick Start

### 1. Configure API Key ✅ (Done)

API key has been generated and set in `infra/.env`:

```env
OPEN_TERMINAL_API_KEY=a6f66141707c0462ae01d9b0c2ef17cf4e575d7b3d2aac3b87c0c919e846e66d
```

### 2. Start the Stack ✅ (Done)

Container is now running:

```bash
docker compose -f infra/open-terminal-isolated.compose.yml up -d
```

### 3. Check Status ✅ (Done)

View running containers:

```bash
docker ps | grep open-terminal
```

Current status:

- **Container**: `open-terminal` running
- **Image**: `ghcr.io/open-webui/open-terminal:slim`
- **Port**: `127.0.0.1:8001` → `8000` (internal)
- **Network**: `infra_ot-net` (isolated)
- **Status**: ✅ Up and responding

### 5. Integrate with Open WebUI

In Open WebUI:

1. Go to **Integrations**
2. Add **Open Terminal** connection
3. URL: `http://127.0.0.1:8001`
4. API key: value from `infra/.env`

## Usage Patterns

### Clone and Work on a Project

Inside the open-terminal integration:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/ORG/REPO.git
cd REPO
git checkout -b agent/feature-branch
```

Make changes, then push:

```bash
git add -A
git commit -m "agent: implement feature"
git push origin agent/feature-branch
```

### Soft Wipe (Keep Tools)

After a project, clear workspace but preserve installed tools and caches:

```bash
bash infra/wipe-soft.sh
```

Container continues running. Ready for next project in seconds.

### Hard Wipe (Full Reset)

For high-assurance project isolation, destroy and recreate:

```bash
bash infra/wipe-hard.sh
```

Container is removed and recreated from scratch. All data gone.

### Stop the Stack

```bash
bash infra/stop.sh
```

### Persistent Mode (Optional)

If you need `/home/user` to survive container restarts:

```bash
docker compose -f infra/open-terminal-isolated-persistent.compose.yml up -d
```

⚠️ Trade-off: You lose the automatic wipe-on-restart guarantee. Use `wipe-hard.sh` when switching projects.

## Architecture

```
┌─────────────────────────────────────┐
│         Open WebUI                  │
│    (Integrations → Terminal)        │
└────────────────┬────────────────────┘
                 │ HTTP
                 ▼
    ┌────────────────────────┐
    │ ot-net (bridge)        │
    │  └─ open-terminal      │
    │     (port 8000)        │
    └────────────────────────┘
                 ●
    ┌────────────────────────┐
    │ lc-net (bridge)        │
    │  └─ little-coder       │
    │     (agent runtime)    │
    └────────────────────────┘

Key property: ot-net and lc-net are isolated.
open-terminal cannot see little-coder and vice versa.
```

## Security Guarantees

### Isolation

- **No shared network**: `open-terminal` and `little-coder` are on separate bridge networks
- **No Docker socket**: Neither container can create, delete, or inspect other containers
- **Ephemeral by default**: Container state is wiped on each hard wipe or container recreate

### Containment

- **Read-only filesystem**: Root FS cannot be modified; only `/tmp`, `/run`, `/home/user` are writable
- **Dropped capabilities**: No `CAP_SYS_ADMIN`, `CAP_NET_ADMIN`, `CAP_DAC_OVERRIDE`, etc.
- **Resource limits**: CPU, memory, and process count bounded

### Observability

- **Loopback-only port**: Port 8000 is not exposed to LAN or external interfaces
- **Audit trail**: Commands executed in container leave logs visible via `docker logs`

## Token and Credential Guidance

For GitHub access inside open-terminal:

1. **Generate a fine-grained personal access token** on GitHub:
   - Scoped to specific repositories
   - Permissions: `Contents: read/write`, `Pull Requests: write`
   - No admin or org-level scope

2. **Inject at runtime** (do not hardcode):

   ```bash
   docker exec -it open-terminal gh auth login --with-token < token.txt
   ```

3. **Or use environment variable**:

   ```bash
   docker run ... -e GITHUB_TOKEN=$GITHUB_TOKEN ...
   ```

4. **Rotate tokens regularly** (monthly recommended)

## Verification Checklist

After startup, verify:

```bash
bash infra/verify-security.sh
```

This checks:

- ✓ No docker.sock mounts
- ✓ Read-only root filesystem
- ✓ Loopback-only port binding
- ✓ All capabilities dropped
- ✓ no-new-privileges flag set
- ✓ Separate networks (ot-net, lc-net)
- ✓ Resource limits applied

## Troubleshooting

### Container fails to start

Check logs:

```bash
docker compose -f infra/open-terminal-isolated.compose.yml logs open-terminal
```

Common issues:

- API key is placeholder → set it in `.env`
- Port 8000 already in use → change port binding or stop conflicting container
- Image not found → `docker pull ghcr.io/open-webui/open-terminal:slim`

### "Permission denied" inside container

This is expected with `read_only: true`. Use `/tmp`, `/run`, or `/home/user` for writes.

### Network isolation check

Verify containers cannot see each other:

```bash
# From inside open-terminal, try to reach little-coder
docker exec -it open-terminal ping little-coder
# Result: "ping: cannot resolve little-coder"  ← Expected, confirms isolation
```

### Egress restrictions

For production, add firewall rules to limit open-terminal egress:

- Allow: GitHub.com (git clone, push)
- Allow: Model API endpoints (if needed)
- Deny: Everything else

## Operational Runbook

**Daily Startup:**

```bash
bash infra/start.sh
bash infra/verify-security.sh
```

**Per-Project Workflow:**

1. Integrate terminal in Open WebUI
2. Clone repo inside container
3. Create feature branch
4. Implement, commit, push
5. Run wipe (soft or hard based on sensitivity)

**Shutdown:**

```bash
bash infra/stop.sh
```

**Full Reset (if issues):**

```bash
bash infra/wipe-hard.sh
bash infra/verify-security.sh
```

## Future Hardening

If you need stronger controls:

1. **User namespaces**: Run containers as non-root user inside namespace
2. **AppArmor/SELinux**: Custom profile tailored to terminal workloads
3. **mTLS + IP allowlist**: Reverse proxy in front of Open WebUI
4. **One-time containers**: Spawn isolated container per project, destroy when done
5. **Egress firewall**: Host-level or Docker policy to block unauthorized outbound connections

See [docs/plans/openterminal-workspace.md](../docs/plans/openterminal-workspace.md#notes-for-future-hardening) for details.

## References

- [Open Terminal Documentation](https://github.com/open-webui/open-terminal)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP: Container Security Top 10](https://owasp.org/Container-Security/)
