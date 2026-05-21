---
topic: git_authorship
keywords: [git, author, commit, identity, user.name, user.email, config, attribution, pat, signature, committer, name, email]
token_cost: 150
requires_tools: [ShellSession]
---
Commits MUST be attributed to little-coder, NOT to the human owner of the PAT used for authentication. The PAT only authorizes the push; the commit author is metadata you control via `git config`.

Set these once per fresh clone (or once globally if working in a long-lived workspace):

```
git config user.name  "little-coder"
git config user.email "little-coder@users.noreply.github.com"
```

Rules:
- Run the two `git config` commands immediately after `git clone`, before the first commit. If you commit first, fix retroactively with `git commit --amend --reset-author` (and ONLY on unpushed commits).
- Verify with `git config user.name` and `git log -1 --format='%an <%ae>'` before pushing.
- Never use the PAT owner's name even if `git log` on existing commits shows them as the recent author — that is their history, not yours.
- Do not set `--global` unless the user explicitly asks; per-repo config keeps attribution scoped and prevents accidental leakage into unrelated projects.
- If the user supplies a different agent identity (e.g. `little-coder[bot]`), use exactly what they give and confirm via `git log` after the first commit.
