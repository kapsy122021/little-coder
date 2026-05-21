---
topic: clean_code_naming
keywords: [naming, name, variable, function, method, class, readable, clean, code, identifier, rename, convention, style, magic, number, comment]
token_cost: 150
requires_tools: []
---
Names are documentation. Optimise for the reader, not the writer.

- **Reveal intent.** `daysUntilExpiry` not `d`. `customersWithOverdueInvoices` not `list2`.
- **Match the grain.** Loop indices may be `i, j`; domain entities may not.
- **Verbs for functions, nouns for things.** `calculateTax()`, `Invoice`, `isOverdue` (booleans read like questions).
- **No type-encoded prefixes** (`strName`, `lstUsers`) — types belong to the type system.
- **No misleading shortcuts.** `acct` is fine; `accntMgr` is not. Abbreviate only what the whole team would.
- **Symmetry of opposites.** `open`/`close`, `start`/`stop`, `add`/`remove` — never `open`/`dismiss`.
- **Magic numbers → named constants** with units in the name (`TIMEOUT_SECONDS = 30`).
- **Comments are the last resort.** If the code needs prose to be understood, rename a thing or extract a function first. Reserve comments for *why*, not *what*.
- **Function size.** If you cannot hold the function in one screen, it is doing more than one thing — extract until each function reads as a small sequence of named steps.
