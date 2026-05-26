# update-little-coder

Portable workflow to update little-coder inside a running Docker container, then lock that exact updated state into Docker image tags.

The updater now also enforces the local-only runtime policy used by this workspace (open-terminal routing, local models file, loopback-only terminal exposure, and no Docker socket mounts).

## Files

- `update-little-coder-container.cmd`: updates in-container little-coder and creates locked image tags.

## Prerequisites

- Docker Desktop (or Docker CLI) available on PATH.
- A running container that has little-coder installed (default name: `little-coder`).
- Windows shell (cmd or PowerShell).

## Quick Start

From this folder:

```bat
.\update-little-coder-container.cmd little-coder latest little-coder-lock
```

This does all of the following:

1. Validates the container is running.
2. If needed, starts the compose stack from `infra/docker-compose.yml`.
3. Enforces `LLAMACPP_BASE_URL` in `infra/.env` and recreates the little-coder container so policy env vars are active.
4. Validates policy controls:
   - `LITTLE_CODER_USE_OPEN_TERMINAL=1`
   - `OPEN_TERMINAL_URL=http://open-terminal:8000`
   - `LITTLE_CODER_MODELS_FILE=/app/docker.models.json`
   - `/app/docker.models.json` has only `providers.llamacpp`
   - `open-terminal` port bind is loopback-only (`127.0.0.1`)
   - no `/var/run/docker.sock` mount in either container
5. Backs up `/app/docker.models.json` and `~/.pi/agent/settings.json` inside container temp storage.
6. Runs uninstall-first repair to avoid EEXIST collisions:
   - `npm uninstall -g little-coder`
   - `rm -f /usr/local/bin/little-coder`
7. Installs `little-coder@<target>`.
8. Detects installed version.
9. Commits container to locked tags:
   - `<image-repo>:lc-v<detected-version>`
   - `<image-repo>:latest`

## Usage

```bat
.\update-little-coder-container.cmd [container_name] [target_version] [image_repo] [llamacpp_base_url] [--no-pause]
```

Defaults:

- `container_name`: `little-coder`
- `target_version`: `latest`
- `image_repo`: `little-coder-lock`
- `llamacpp_base_url`: `http://host.docker.internal:8000/v1`
- `--no-pause`: optional (do not wait for keypress on either success or failure)

Note: full autonomous policy enforcement (auto-start, `.env` update, and recreate) applies to the default container name `little-coder`. For custom container names, the script still updates and locks the running container, and validates the same policy envs; it just does not manage compose lifecycle for that custom name.

Examples:

```bat
.\update-little-coder-container.cmd
.\update-little-coder-container.cmd little-coder 1.8.1 little-coder-lock
.\update-little-coder-container.cmd my-container latest my-lock-repo
.\update-little-coder-container.cmd little-coder latest little-coder-lock http://host.docker.internal:8000/v1
.\update-little-coder-container.cmd little-coder latest little-coder-lock http://host.docker.internal:8000/v1 --no-pause
```

## Double-click usage

Open File Explorer to this folder and double-click `update-little-coder-container.cmd`.

It will run with defaults:

- container: `little-coder`
- target: `latest`
- image repo: `little-coder-lock`
- llama egress: `http://host.docker.internal:8000/v1`

To pin a specific version or alternate egress URL, run it from a terminal with arguments.

## Verify

```powershell
docker image ls --format "table {{.Repository}}`t{{.Tag}}`t{{.ID}}`t{{.CreatedSince}}" | Select-String "little-coder-lock|REPOSITORY"
```

## Recreate container from locked image

Use your existing compose/run workflow, but point the image to the lock tag you want, for example:

- `little-coder-lock:latest` for rolling latest locked snapshot
- `little-coder-lock:lc-v1.8.1` for a specific pinned version
