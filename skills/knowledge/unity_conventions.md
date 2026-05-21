---
topic: unity_conventions
keywords:
  [
    unity,
    monobehaviour,
    gameobject,
    scriptableobject,
    serializefield,
    prefab,
    unity3d,
    component,
    coroutine,
    awake,
    start,
    update,
    fixedupdate,
    asmdef,
    editor,
    inspector,
  ]
token_cost: 150
requires_tools: []
---

Unity overrides plain C# conventions where they conflict. Apply these when the project contains Unity assets, `*.asmdef` files, or `using UnityEngine;`:

- **Naming.** Still `PascalCase` for types and methods, but inspector-visible private fields use `[SerializeField] private` with a `camelCase` (no `_` prefix) so the inspector label reads naturally. Public fields are tolerated on `MonoBehaviour`/`ScriptableObject` for inspector-bound data, but prefer `[SerializeField] private` + a public read-only property.
- **Component access.** Cache `GetComponent<T>()` in `Awake`, never call it in `Update`. The same goes for `Camera.main` and `FindObjectOfType` — both are O(scene).
- **Lifecycle.** `Awake` for self-init, `Start` for cross-component wiring (other components have run their `Awake`). `OnEnable`/`OnDisable` for subscription pairs. Keep `Update` allocation-free; move heavy work to coroutines or `InvokeRepeating`.
- **Allocations.** No `new` per frame in hot paths. Pool `List<T>` and arrays; use `NonAlloc` physics overloads (`Physics.RaycastNonAlloc`).
- **ScriptableObjects** for shared, designer-tunable data — not singletons in code.
- **Asmdef boundaries.** One assembly per feature area (`Game.Combat.Runtime`, `Game.Combat.Editor`). Editor-only code under `/Editor/` folders with editor asmdefs to keep it out of player builds.
- **Coroutines vs async.** Coroutines for frame-tied work; `UniTask`/`async` for IO. Do not mix lifetimes — a coroutine on a destroyed GameObject silently stops; an `async` task does not.
