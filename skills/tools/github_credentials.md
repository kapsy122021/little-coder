---
name: github-credentials
type: tool-guidance
target_tool: OTBash
priority: 8
token_cost: 140
user-invocable: false
---

## GitHub authentication (OTBash)

You (little-coder) run inside a Docker container. You do NOT have direct
filesystem access — all shell commands go through the **OTBash tool**, which
executes them inside a separate open-terminal container. That container has
a git credential store pre-configured by the user on the host. You never
see the tokens and should never ask for them.

### Cloning a repo

Use OTBash with a plain HTTPS URL — authentication is automatic:

```
git clone https://github.com/owner/repo.git
```

No `GITHUB_TOKEN`, no `-e`, no token in the URL. The credential helper
inside open-terminal resolves the right token from `/home/user/.git-credentials`
based on the URL path.

### Pushing

After committing, `git push` works the same way — no extra flags needed.

### If a clone or push fails with a 401 or 403

Tell the user to open the `credentials` file in the `infra/git/` folder of
the little-coder project on their **host machine** and add a line for the
failing repo:

```
https://x-access-token:ghp_xxx@github.com/<owner>/<repo>
```

No restart is needed — the file is bind-mounted live into open-terminal.

You cannot access that file yourself — it lives on the host outside both
containers. Direct the user to edit it manually.

### What NOT to do

- Do not embed tokens in URLs (`https://ghp_xxx@github.com/...`) — they
  leak into git history and `.git/config`.
- Do not set `GITHUB_TOKEN` env vars in OTBash calls — the credential
  helper handles auth; env tokens are redundant and won't help if the
  credentials file is missing an entry.
- Do not run `git config credential.helper ...` — it's already configured
  via a read-only bind mount; the change would be silently ignored.
- Do not write credential files inside `/home/user/projects/` — that
  directory is wiped between sessions.
