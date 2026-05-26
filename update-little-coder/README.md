# update-little-coder

Portable workflow to update little-coder inside a running Docker container, then lock that exact updated state into Docker image tags.

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
2. Backs up `/app/docker.models.json` and `~/.pi/agent/settings.json` inside container temp storage.
3. Runs uninstall-first repair to avoid EEXIST collisions:
   - `npm uninstall -g little-coder`
   - `rm -f /usr/local/bin/little-coder`
4. Installs `little-coder@<target>`.
5. Detects installed version.
6. Commits container to locked tags:
   - `<image-repo>:lc-v<detected-version>`
   - `<image-repo>:latest`

## Usage

```bat
.\update-little-coder-container.cmd [container_name] [target_version] [image_repo]
```

Defaults:

- `container_name`: `little-coder`
- `target_version`: `latest`
- `image_repo`: `little-coder-lock`

Examples:

```bat
.\update-little-coder-container.cmd
.\update-little-coder-container.cmd little-coder 1.8.1 little-coder-lock
.\update-little-coder-container.cmd my-container latest my-lock-repo
```

## Verify

```powershell
docker image ls --format "table {{.Repository}}`t{{.Tag}}`t{{.ID}}`t{{.CreatedSince}}" | Select-String "little-coder-lock|REPOSITORY"
```

## Recreate container from locked image

Use your existing compose/run workflow, but point the image to the lock tag you want, for example:

- `little-coder-lock:latest` for rolling latest locked snapshot
- `little-coder-lock:lc-v1.8.1` for a specific pinned version
