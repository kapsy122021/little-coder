---
topic: code_quality_review
keywords:
  [
    review,
    quality,
    refactor,
    check,
    checklist,
    done,
    finish,
    complete,
    solid,
    naming,
    encapsulation,
    smell,
    lint,
    ready,
  ]
token_cost: 150
requires_tools: [Read, Edit]
---

## Self-review protocol (run before declaring "done")

Re-read every file you changed in this task. Score it against this checklist. Fix anything that fails before you stop.

**Naming**

- Each new identifier reveals intent without a comment.
- No `data`, `temp`, `helper`, `manager`, `util` as a top-level noun.
- Booleans read as questions (`isReady`, `hasItems`).

**Encapsulation**

- Smallest visibility that compiles. No `public` field unless the platform requires it (e.g. Unity `[SerializeField]`).
- No mutable collection returned from a public method.
- Invariants enforced at construction, not by every caller.

**SOLID smell-check**

- One reason to change per class. No "And" in the class name.
- No growing `switch (type)` in a stable class — extension point instead.
- Dependencies passed in, not `new`-ed inside, when a test will need to fake them.

**Hygiene**

- No commented-out code blocks.
- No `print` / `Debug.Log` / `console.log` left from debugging.
- No TODOs you intend to do today — do them, or file an issue and link it.
- Tests, lint, and build are green. If you didn't run them, run them now.

**Convention alignment**

- C# files match Microsoft conventions; Unity files match Unity conventions; the rest matches the repo's existing style (look at a neighbouring file).

Fail any item → fix it. Do not negotiate with yourself.
