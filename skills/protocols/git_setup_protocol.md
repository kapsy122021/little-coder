---
topic: git_setup_protocol
keywords:
  [
    git,
    clone,
    setup,
    init,
    configure,
    identity,
    fresh,
    new,
    repo,
    repository,
    start,
    project,
    onboard,
  ]
token_cost: 150
requires_tools: [ShellSession]
---

## Fresh-clone setup protocol

Run this exact sequence the first time you touch a repo in an open-terminal session. It costs four commands and prevents the two most common follow-up failures (commits attributed to the PAT owner, work lost to `wipe-soft`).

1. `cd /home/user/projects && git clone https://github.com/<owner>/<repo>.git` — plain HTTPS, no token in URL. Credential helper resolves auth.
2. `cd <repo>`
3. Set little-coder authorship per-repo (NOT global):
   ```
   git config user.name  "little-coder"
   git config user.email "little-coder@users.noreply.github.com"
   ```
4. Verify: `git config user.name && git remote -v && git status` — confirm name, that `origin` points to the expected URL, and the tree is clean.

Then, before writing any code:

- `ls .little-coder/journal/ 2>/dev/null` — check for prior session notes on this repo.
- `cat AGENTS.md CLAUDE.md README.md 2>/dev/null | head -200` — surface repo conventions.

Skip step 3 only if `git config user.name` already returns `little-coder` (e.g. mid-session re-clone).
