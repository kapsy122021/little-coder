# Open Terminal Isolated Workspace Guide

## Goal

Run open-terminal as a separate, disposable execution environment from little-coder so that:

1. open-terminal cannot break or delete the little-coder container.
2. Each project can start from a clean terminal state.
3. Code synchronization happens through Git, not host path mounts.
4. Minimize host exposure (air-gap posture) by default.

This guide assumes Docker Compose v2 and GitHub.

## Architecture

Use two independent containers:

1. `little-coder`: your agent runtime container.
2. `open-terminal`: terminal execution container used by Open WebUI integration.

Use separate Docker networks:

1. `ot-net`: Open WebUI <-> open-terminal traffic only.
2. `lc-net`: little-coder traffic only.

Do not place `little-coder` and `open-terminal` on the same bridge network unless there is a strict functional requirement.

Key rule: do not mount Docker socket in either container.

That means do not mount:

1. `/var/run/docker.sock:/var/run/docker.sock`

Without Docker socket access, one container cannot manage or delete the other.

## Security Findings Applied (Host Air-Gap)

This guide now applies these audit findings as default controls, not optional controls:

1. Do not expose Open Terminal on all host interfaces.
2. Do not place open-terminal and little-coder on a shared network.
3. Use stronger runtime hardening (`read_only`, `tmpfs`, non-root where possible, seccomp/AppArmor).
4. Enforce egress restrictions (GitHub/model endpoints only) at host firewall or Docker policy layer.
5. Apply CPU, memory, and process limits to reduce host availability risk.

## Security Model

Apply these controls to both containers:

1. No privileged mode.
2. Drop all Linux capabilities (`cap_drop: ["ALL"]`).
3. Enforce `no-new-privileges`.
4. Use `read_only: true` and explicit writable `tmpfs` mounts.
5. Apply resource limits (`pids_limit`, `mem_limit`, `cpus`).
6. Use default Docker seccomp + AppArmor/SELinux profile on the host.

Apply these controls specifically to open-terminal:

1. No host bind mount of source code.
2. Bind service port to loopback only.
3. Use ephemeral mode by default (no persistent volume) for strict wipe between projects.
4. If persistence is needed, use a dedicated named volume for `/home/user` and hard wipe between projects.
5. Restrict outbound network access to required endpoints only.
6. Use fine-grained GitHub token with minimal repository scope.

## Implementation (Docker Compose)

Create a compose file, for example `infra/open-terminal-isolated.compose.yml`:

```yaml
services:
	open-terminal:
		image: ghcr.io/open-webui/open-terminal:slim
		container_name: open-terminal
		restart: unless-stopped
		# Bind only on host loopback to avoid LAN exposure
		ports:
			- "127.0.0.1:8000:8000"
		environment:
			OPEN_TERMINAL_API_KEY: ${OPEN_TERMINAL_API_KEY}
			OPEN_TERMINAL_MULTI_USER: "false"
		# Strict wipe by default: no persistent volume mounted.
		# If you need persistence, see "Persistent Variant" below.
		read_only: true
		tmpfs:
			- /tmp:size=256m,noexec,nosuid,nodev
			- /run:size=64m,nosuid,nodev
			- /home/user:size=4g,nosuid,nodev
		networks:
			- ot-net
		cap_drop:
			- ALL
		security_opt:
			- no-new-privileges:true
			- seccomp=default
		pids_limit: 256
		mem_limit: 2g
		cpus: 2

	little-coder:
		image: your-little-coder-image:latest
		container_name: little-coder
		restart: unless-stopped
		stdin_open: true
		tty: true
		# Keep this isolated from open-terminal by default.
		networks:
			- lc-net
		read_only: true
		tmpfs:
			- /tmp:size=256m,noexec,nosuid,nodev
			- /run:size=64m,nosuid,nodev
		cap_drop:
			- ALL
		security_opt:
			- no-new-privileges:true
			- seccomp=default
		pids_limit: 256
		mem_limit: 2g
		cpus: 2

networks:
	ot-net:
		driver: bridge
	lc-net:
		driver: bridge
```

Persistent variant for open-terminal (`/home/user` survives restarts):

```yaml
services:
	open-terminal:
		read_only: false
		volumes:
			- open-terminal-home:/home/user

volumes:
	open-terminal-home:
```

Create `.env` next to the compose file:

```env
OPEN_TERMINAL_API_KEY=replace-with-long-random-secret
```

Start stack:

```bash
docker compose -f infra/open-terminal-isolated.compose.yml up -d
```

## Open WebUI Integration

In Open WebUI:

1. Go to Integrations.
2. Add Open Terminal connection.
3. URL: `http://127.0.0.1:8000` (or reverse proxy URL).
4. API key: value of `OPEN_TERMINAL_API_KEY`.

Use this as a terminal integration, not as a tool server.

## Git-Only Project Workflow

Inside open-terminal, treat each project as a Git checkout.

Example per project:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/ORG/REPO.git
cd REPO
git checkout -b agent/$(date +%Y%m%d-%H%M%S)
```

After work:

```bash
git add -A
git commit -m "agent: update"
git push origin HEAD
```

Then open a pull request in GitHub.

## Wipe Strategy Between Projects

You have two good wipe patterns.

Recommendation: use hard wipe as default for high-assurance project isolation.

### Option A: Soft wipe (fast)

Keep container running, clear workspace directory only:

```bash
docker exec -it open-terminal sh -lc 'rm -rf /home/user/projects/*'
```

Use when you want to preserve installed tools and caches but remove project files.

### Option B: Hard wipe (cleanest)

Destroy container and recreate. For persistent mode, remove named volume too:

```bash
docker compose -f infra/open-terminal-isolated.compose.yml down
docker volume rm open-terminal-home
docker compose -f infra/open-terminal-isolated.compose.yml up -d
```

Use when you want full reset of home directory, shell history, and all project data.

## Optional: Ephemeral Open Terminal Per Project

For strict project isolation, run a one-off open-terminal container per project:

```bash
docker run --rm -d \
	--name open-terminal-proj-001 \
	-p 127.0.0.1:8001:8000 \
	-e OPEN_TERMINAL_API_KEY=${OPEN_TERMINAL_API_KEY} \
	--read-only \
	--tmpfs /tmp:size=256m,noexec,nosuid,nodev \
	--tmpfs /run:size=64m,nosuid,nodev \
	--tmpfs /home/user:size=4g,nosuid,nodev \
	--cap-drop ALL \
	--pids-limit 256 \
	--memory 2g \
	--cpus 2 \
	--security-opt no-new-privileges:true \
	ghcr.io/open-webui/open-terminal:slim
```

When done:

```bash
docker rm -f open-terminal-proj-001
```

No persistent volume means the workspace is wiped automatically on removal.

## Token and Credential Guidance

Use a fine-grained GitHub token:

1. Restrict token to specific repositories.
2. Grant only required permissions (usually Contents read/write, Pull Requests write).
3. Rotate regularly.

Recommended practice:

1. Inject token as environment variable when needed.
2. Use credential helper or `gh auth login` inside container.
3. Do not hardcode tokens in scripts or commit them to repo.

## Verification Checklist

Validate isolation and wipe behavior:

1. `docker inspect open-terminal` shows no `/var/run/docker.sock` mount.
2. `docker inspect little-coder` shows no `/var/run/docker.sock` mount.
3. `docker inspect open-terminal` confirms `HostConfig.ReadonlyRootfs=true`.
4. `docker inspect little-coder` confirms `HostConfig.ReadonlyRootfs=true`.
5. `docker ps` / `docker inspect` confirms open-terminal is bound to `127.0.0.1` only.
6. `docker inspect` confirms open-terminal and little-coder are on separate networks.
7. A delete inside open-terminal cannot delete files in little-coder container.
8. Soft wipe removes all project working trees under `/home/user/projects`.
9. Hard wipe recreates empty `/home/user` state.
10. Outbound firewall policy limits open-terminal egress to GitHub and model endpoints.

## Operational Runbook

Daily start:

```bash
docker compose -f infra/open-terminal-isolated.compose.yml up -d
```

New project session:

1. Open terminal integration in Open WebUI.
2. Clone target repository.
3. Create fresh branch.
4. Implement changes.
5. Commit and push.
6. Open pull request.
7. Soft or hard wipe depending on sensitivity.

Shutdown:

```bash
docker compose -f infra/open-terminal-isolated.compose.yml down
```

## Notes for Future Hardening

If you need stronger controls later:

1. Run open-terminal rootless or with user namespaces remap.
2. Add AppArmor/SELinux profile tuned for terminal workloads.
3. Put Open WebUI behind reverse proxy with mTLS and IP allowlist.
4. Run one container per user/project for stronger tenancy separation.
5. Add CI checks that reject direct pushes to protected branches.
