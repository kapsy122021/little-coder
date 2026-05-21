---
topic: journal_first_protocol
keywords:
  [
    journal,
    prior,
    history,
    lesson,
    recall,
    previous,
    before,
    start,
    task,
    lookup,
    check,
    notes,
    memory,
  ]
token_cost: 140
requires_tools: [Glob, Read]
---

## Journal-first protocol

Before researching, writing code, or running expensive tool loops on a non-trivial task, spend one cheap round checking whether you (or a previous session) already solved it.

1. `Glob` `.little-coder/journal/*.md` in the current repo. Skip if the directory does not exist.
2. Scan filenames (they encode the date and slug). Read any whose slug overlaps the current task's nouns/verbs.
3. Also `Read` `.little-coder/journal/README.md` if present — it is the human-curated index.
4. If a relevant entry exists, treat its _Approach that worked_ as the default plan and its _What I tried first and why it failed_ as the things to avoid. Verify it still applies (file paths, dependency versions) before blindly following.
5. If no entry applies, proceed normally — but commit to writing one when you finish (see `lesson_capture_protocol`).

Stop conditions:

- Found a directly applicable entry → adopt its plan, skip rediscovery.
- Found a partial match → mine it for gotchas, then plan fresh.
- Nothing found → continue; you will write the first entry for this class of problem.

This protocol is cheap (one Glob + a few Reads) and routinely saves 5–20 tool calls on recurring problems.
