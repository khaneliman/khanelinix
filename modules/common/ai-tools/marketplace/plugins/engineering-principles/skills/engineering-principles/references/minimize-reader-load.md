# Minimize Reader Load

Measure maintainability on two axes:

1. Layers a reader must trace between a question and its answer.
2. Hidden or mutable state a reader must hold while tracing it.

- Collapse wrappers with one caller and adapters with no distinct policy.
- Make adjacent layers change abstraction. Remove pass-through methods that
  repeat the same arguments and operations.
- Keep a boundary only when it hides meaningful decisions or complexity.
- Prefer pure functions, then local state, then object state, then module state.
  Avoid global state.
- Derive values instead of synchronizing duplicate state.
- Name an invariant once at its boundary instead of repeating it in consumers.

Before adding a layer or state, identify the reader load it removes elsewhere.
If a new reader cannot find where a value comes from and what can change it,
reduce indirection or state scope.
