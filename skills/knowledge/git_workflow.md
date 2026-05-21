---
topic: git_workflow
keywords: [git, clone, branch, commit, push, pull, merge, rebase, repo, repository, checkout, fetch, origin, remote, status, diff, log]
token_cost: 150
requires_tools: [ShellSession]
---
Standard git loop inside open-terminal:

1. `git status` before every change — know what's dirty.
2. Work on a topic branch: `git switch -c feat/<short-slug>`. Never commit straight to `main`/`master` unless the user asked.
3. `git add -p` for review; reserve `git add -A` for bulk first commits.
4. `git commit -m "<type>: <imperative summary>"`. One logical change per commit. Run tests first if they exist.
5. `git push -u origin <branch>` — `-u` only on the first push of a new branch.
6. `git pull --rebase` to update, never plain `pull` on shared branches (avoids merge-commit noise).
7. After a push, surface the PR URL the remote prints in its stderr — do not invent one.

Recovery cheatsheet: `git reflog` finds detached commits; `git restore --staged <f>` un-stages; `git switch -` returns to the previous branch. Never use `git push --force` (use `--force-with-lease` if absolutely required, and only after asking the user).
