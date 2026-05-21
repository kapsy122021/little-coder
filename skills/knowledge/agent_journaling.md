---
topic: agent_journaling
keywords: [journal, journaling, memory, notes, log, history, anthropic, agent, learn, lesson, retrospective, knowledge, accumulate, sustainable, context, save, persistent]
token_cost: 150
requires_tools: [Read, Write, Edit, Glob]
---
Anthropic-style agentic journaling: durable, per-workspace notes that let future-you skip work you already did. Cheaper than re-deriving from context every session.

Layout (per-project, lives in the repo so it survives `wipe-soft`):

```
<repo>/.little-coder/
├── journal/
│   ├── README.md           ← index, one line per entry, newest first
│   └── YYYY-MM-DD-<slug>.md  ← one file per non-trivial task
└── skills/
    ├── knowledge/<topic>.md
    └── tools/<tool>.md
```

Each journal entry: ~10 lines max. Frontmatter `date`, `task`, `outcome`. Body: *Problem*, *Approach that worked*, *What I tried first and why it failed*, *Files touched*, *Follow-ups*.

When to write what:
- **Journal entry** for a one-off solved problem (a flaky test, a config quirk, a non-obvious refactor).
- **Project skill** (`<repo>/.little-coder/skills/...`) when the lesson generalises beyond this task within this repo.
- **Bundled skill** (`<pkgRoot>/skills/...`, requires the user to commit + rebuild) when the lesson generalises across every repo little-coder touches.

Read before you write: `Glob` `.little-coder/journal/*.md`, then `Read` any entry whose title matches your current task. Skip exhaustive re-discovery if a prior entry already covers the gotcha.
