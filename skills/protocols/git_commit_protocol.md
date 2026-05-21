---
topic: git_commit_protocol
keywords:
  [
    commit,
    message,
    conventional,
    atomic,
    push,
    stage,
    diff,
    review,
    changelog,
    history,
  ]
token_cost: 150
requires_tools: [ShellSession]
---

## Commit protocol

One commit = one logical change. If you cannot describe it in a single short imperative sentence, split it.

Before committing:

1. `git status` — confirm only intended paths are dirty.
2. `git diff --staged` after `git add` — read your own change as a reviewer would. Spot stray prints, commented-out blocks, leftover TODOs.
3. Run the project's test/lint command if one exists. Do not commit red tests unless the user asked for a WIP commit.

Message format (Conventional Commits):

```
<type>(<scope>): <imperative summary, ≤72 chars>

<optional body explaining WHY, wrapped at 72>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `build`, `ci`. Use `fix(parser):` not `Fixed the parser`.

Forbidden:

- `git commit -am` without first reading `git status` — pulls in unintended files.
- `git commit --amend` after `git push` — rewrites public history.
- `git push --force` — use `--force-with-lease` and only with the user's explicit OK.
- Co-author trailers attributing the work to the PAT owner. You authored it; sign as little-coder.

After push: surface the PR/compare URL the remote prints. Do not fabricate it.
