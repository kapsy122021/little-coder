---
topic: csharp_conventions
keywords:
  [
    csharp,
    c#,
    dotnet,
    .net,
    microsoft,
    convention,
    style,
    naming,
    pascalcase,
    camelcase,
    namespace,
    async,
    await,
    property,
    field,
    interface,
    nullable,
  ]
token_cost: 150
requires_tools: []
---

Microsoft C# conventions (apply by default unless the repo's `.editorconfig` says otherwise):

- **Naming.** `PascalCase` for types, methods, properties, events, public/internal fields, constants. `camelCase` for parameters and locals. `_camelCase` for private instance fields. `I`-prefix for interfaces (`IRepository`). `T`-prefix for generic type params (`TItem`).
- **File layout.** One top-level type per file, file named after the type. File-scoped `namespace MyCo.MyApp;` (single-line, no braces) in modern projects.
- **Async.** Suffix every Task-returning method with `Async`. Never `async void` except for event handlers. Pass `CancellationToken` as the last parameter; default it to `default` only at top-level entry points.
- **Properties.** Auto-properties unless you need a back-store. `{ get; init; }` for immutability after construction. Avoid public setters on collections — expose `IReadOnlyList<T>`.
- **Null.** Enable `<Nullable>enable</Nullable>` at the project level. Annotate intent with `?` rather than scattering null-checks. Prefer pattern matching (`is not null`) over `!= null`.
- **Exceptions.** Throw specific types (`ArgumentNullException.ThrowIfNull(x)`). Never `throw ex;` — use plain `throw;` to preserve the stack.
- **`var`.** Use when the right-hand side makes the type obvious (`var users = new List<User>();`). Spell the type out when it does not.
- **`using` declarations.** Prefer the declaration form (`using var stream = ...;`) over the block form for simple cases.
