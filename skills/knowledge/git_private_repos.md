---
topic: git_private_repos
keywords: [private, repo, repository, clone, authentication, auth, credentials, token, pat, 401, 403, forbidden, unauthorized, github, gitlab, push, permission]
token_cost: 150
requires_tools: [ShellSession]
---
Private-repo authentication inside open-terminal is handled by a bind-mounted credential store at `/home/user/.git-credentials` plus a pre-configured `credential.helper=store` in `/home/user/.gitconfig`. Both are read-only mounts owned by the host.

Workflow:
- Always clone with the plain HTTPS URL: `git clone https://github.com/<owner>/<repo>.git`. The helper picks the right token for that host/path automatically.
- Never embed a token in the URL or in `.git/config` — it leaks into history and is rejected by `push.useForceIfIncludes`.
- Never `export GITHUB_TOKEN=...` — the helper is the single source of truth.
- Never run `git config credential.helper ...` — the read-only mount makes the change a silent no-op.

On `fatal: Authentication failed` / HTTP 401 or 403: stop and tell the user to add a line to `infra/git/credentials` on the host in the form `https://x-access-token:<PAT>@github.com/<owner>/<repo>`. The mount is live; no restart required. You cannot edit that file yourself — it lives outside both containers.
