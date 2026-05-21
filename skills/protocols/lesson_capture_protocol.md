---
topic: lesson_capture_protocol
keywords: [lesson, capture, retrospective, learn, journal, write, after, finish, complete, done, postmortem, takeaway, accumulate, skill]
token_cost: 150
requires_tools: [Write, Edit, Glob]
---
## Lesson-capture protocol

After completing a non-trivial task, before declaring done, spend one round turning the experience into a durable artefact. Future-you (and future-other-agents) reads it instead of re-deriving.

Decide what to write based on generality:

| Scope                        | Where                                            | Form                |
|------------------------------|--------------------------------------------------|---------------------|
| This task only               | `<repo>/.little-coder/journal/YYYY-MM-DD-<slug>.md` | Journal entry       |
| Recurs in this repo          | `<repo>/.little-coder/skills/knowledge/<topic>.md`  | Project skill       |
| Recurs across every repo     | (propose to the user) `<pkgRoot>/skills/...`     | Bundled skill PR    |

Journal entry template (keep it under ~15 lines):
```
---
date: YYYY-MM-DD
task: <one-line summary>
outcome: success | partial | abandoned
---
**Problem.** ...
**Approach that worked.** ...
**Tried first and why it failed.** ...
**Files touched.** path/a, path/b
**Follow-ups.** ...
```

Triggers — write something if ANY of these are true:
- You spent >5 tool calls discovering a single fact.
- You hit an error whose fix was non-obvious from the message.
- The user corrected you mid-task — capture the correction.
- You made a design decision the next agent might question.

Skip for trivial tasks (single-line edits, "what does this file do" Q&A). Capturing every micro-step pollutes the journal and dilutes signal.

After writing, update `<repo>/.little-coder/journal/README.md` with a one-line index entry pointing at the new file.
