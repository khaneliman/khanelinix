# Boundary Discipline

Validate and narrow data once when it crosses a system boundary. Trust typed
internal data after that boundary.

System boundaries include CLI arguments, configuration files, environment
variables, storage rows, network protocols, and external APIs.

- Parse external representations into domain types at the boundary.
- Return useful boundary errors before business logic runs.
- Keep framework, transport, storage, and wire types behind adapters.
- Keep business logic in pure functions when practical.
- Propagate typed errors internally. Do not repeat the same validation in every
  caller.
- Expose domain concepts through public interfaces, not boundary-private data.

Ask two questions. Is data crossing a boundary now? Can the decision be a pure
function called by a thin shell? If the first answer is no, repeated validation
is usually noise. If the second answer is yes, move policy out of the adapter.
