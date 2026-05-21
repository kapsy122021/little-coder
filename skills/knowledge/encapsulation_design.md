---
topic: encapsulation_design
keywords: [encapsulation, hiding, information, public, private, internal, api, surface, boundary, coupling, cohesion, getter, setter, property, mutable, immutable, invariant]
token_cost: 150
requires_tools: []
---
Encapsulation = the public surface is the contract; everything else is replaceable.

- **Default to the narrowest visibility.** Private first, internal/package next, public only when a caller outside the unit genuinely needs it.
- **Hide representation, expose behaviour.** Do not expose mutable collections; return `IReadOnlyList<T>`, defensive copies, or iterator methods. Callers should not be able to mutate your state by accident.
- **Properties over fields** (in C#, Java, etc.). Naked public fields freeze the type's layout into every caller.
- **Avoid leaky abstractions.** Do not return ORM entities, framework handles, or DB rows from a public method that pretends to be domain logic.
- **Constructors enforce invariants.** If `Order` requires at least one line item, the constructor should reject the empty case — not rely on every caller to remember.
- **Tell, don't ask.** `account.Deposit(amount)` beats `if (account.Balance + amount < limit) account.Balance += amount`. Logic that reads private state belongs *on* the type that owns it.
- **One layer per change.** If touching the persistence layer also forces a UI edit, the boundary is in the wrong place.
