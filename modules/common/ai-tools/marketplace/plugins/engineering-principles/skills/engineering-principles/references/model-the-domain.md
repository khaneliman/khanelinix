# Model the Domain

Encode domain rules in a structure instead of scattering them across branches.

Use the structure that matches the data and its operations:

- A state machine for lifecycle states and transitions.
- A typed model for repeated shape assumptions or semantic values.
- A table, registry, map, or union for branching spread across files.
- A reducer or command model for coordinated state changes.
- A module boundary for one body of domain knowledge and its invariants.
- A queue, cache, index, graph, tree, or normalized collection when access
  patterns require it.

Do not force an abstraction. Keep direct code when its shape is clear, local,
and stable. A new structure must remove branches, duplicated rules, invalid
states, or lifecycle risk. Indirection alone is not a benefit.

Before writing logic, name the data shape, its invariants, and the operations it
must support. Repeated conditionals or booleans that must stay synchronized are
signals that the domain model is missing.
