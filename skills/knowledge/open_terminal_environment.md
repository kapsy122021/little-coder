---
topic: open_terminal_environment
keywords:
  [
    container,
    open-terminal,
    openterminal,
    workspace,
    environment,
    filesystem,
    persistence,
    ephemeral,
    projects,
    home,
    mount,
    docker,
    shell,
    session,
  ]
token_cost: 150
requires_tools: [ShellSession]
---

You execute inside the `open-terminal` container, reached over HTTP by the `little-coder` container. Implications:

- Working dir is `/home/user/`. Persist work under `/home/user/projects/<name>/` — that is where the user expects to find clones and outputs.
- `/home/user/projects/` is wiped by `infra/wipe-soft.sh` between sessions; treat anything under it as session-scoped. Long-lived state must be committed and pushed.
- `/home/user/.gitconfig` and `/home/user/.git-credentials` are read-only host bind mounts. Do not try to edit them; ask the user to edit `infra/git/credentials` on the host.
- `ShellSession` is stateful within a session — `cd`, env vars and shell functions persist across calls. Set `cd` and exports once, reuse.
- There is no `sudo`, no systemd, and no second user. Install language-level tooling under the current user (`pip install --user`, `npm config set prefix ~/.npm-global`).
- Network egress is allowed; `host.docker.internal` does NOT resolve from open-terminal — only the `little-coder` container reaches the host LLM. Treat open-terminal as a normal internet-connected Linux box.
- Author durable skills/journal entries into `<repo>/.little-coder/` (project scope) so they survive `wipe-soft` if the repo is checked back out.
