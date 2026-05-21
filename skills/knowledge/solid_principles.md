---
topic: solid_principles
keywords:
  [
    solid,
    srp,
    ocp,
    lsp,
    isp,
    dip,
    design,
    principle,
    single,
    responsibility,
    open,
    closed,
    liskov,
    interface,
    segregation,
    dependency,
    inversion,
    refactor,
    class,
    architecture,
  ]
token_cost: 150
requires_tools: []
---

SOLID, applied at the unit you are actually writing — usually a class or module:

- **S — Single Responsibility.** One reason to change. If the class name has "And" or "Manager" with three nouns, split it.
- **O — Open/Closed.** Add features by extending (new type, new strategy) rather than editing a switch in a stable class. A growing `switch (type)` is the smell.
- **L — Liskov.** A subtype must be drop-in for its base — no narrower preconditions, no stricter return types, no thrown exceptions the base did not promise.
- **I — Interface Segregation.** Many small role-interfaces beat one fat one. Callers should not depend on methods they never call.
- **D — Dependency Inversion.** High-level policy depends on abstractions; concrete adapters depend on those abstractions. Pass dependencies in (ctor injection) rather than `new`-ing them inside.

Pragmatics: do not invent abstractions before the second concrete need. Premature DIP produces interfaces with one implementation and no boundary. Apply when a real seam emerges (testing, swap, plugin), not as a reflex.
