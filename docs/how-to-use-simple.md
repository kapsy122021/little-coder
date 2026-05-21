# little-coder Quick Cheat Sheet (CLI)

Use this when starting from a cold system reboot and for daily basic usage.

## 1) Cold reboot: start containers

From the repo root:

```sh
cd /path/to/little-coder
bash infra/start.sh
```

Check status:

```sh
docker ps --filter "name=little-coder|open-terminal"
```

## 2) Start little-coder

Standard model:

```sh
docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b
```

No-think variant:

```sh
docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b-nothink
```

Exit the agent:

```sh
Ctrl-D
```

## 3) Clone a project (inside open-terminal workspace)

All work projects should live in `/home/user/projects`:

```sh
docker exec -it open-terminal sh -lc "cd /home/user/projects && git clone https://github.com/owner/repo1.git"
```

## 4) Wipe workspace between tasks

Reset only the open-terminal project workspace:

```sh
docker exec open-terminal sh -lc "rm -rf /home/user/projects && mkdir -p /home/user/projects && echo workspace-cleared"
```

Verify it is clean:

```sh
docker exec open-terminal ls -la /home/user/projects
```

Start next run:

```sh
docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b
```

## 5) One-time GitHub PAT wiring (for private repos)

Prereq:
- Set `GITHUB_TOKEN` in your little-coder `.env`.
- Recreate/update containers so env vars are loaded.

```sh
cd /path/to/little-coder/infra
docker compose up -d
```

Configure git credential helper in `open-terminal` (one-time):

```sh
docker exec open-terminal sh -c "git config --global credential.helper '!f() { echo username=x-access-token; echo password=\$GITHUB_TOKEN; }; f'"
```

Verify:

```sh
docker exec open-terminal sh -c "git config --global credential.helper"
```

## 6) Minimal daily flow

```sh
cd /path/to/little-coder
bash infra/start.sh
docker exec -it little-coder little-coder --model llamacpp/qwen3.6:27b
```