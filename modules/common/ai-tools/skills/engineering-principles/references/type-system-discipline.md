# Type System Discipline

Use the type checker to exclude impossible states, mismatched semantic values,
and unhandled variants.

- Model variants with sum types, discriminated unions, enums with payloads, or
  sealed classes. Avoid optional-field bags that admit contradictory states.
- Construct valid values directly. Use a head plus rest for a non-empty list, or
  a start plus duration for an ordered range.
- Give semantic primitives distinct types. User IDs and order IDs must not be
  interchangeable because both use strings.
- Treat external data as untyped until a boundary parser creates a domain type.
- Do not bypass proof with casts, unchecked assertions, or unsafe coercions.
- Make variant matching exhaustive so new cases fail compilation at every
  incomplete use site.
- Derive types from authoritative schemas instead of copying their shape.
- Strengthen a type where a partial operation, assertion, or impossible-case
  branch proves the current type is too weak. Stop when operations are total.

Prefer redesigning the representation over adding runtime guards. Extra type
precision must remove a real failure mode. Precision that only adds ceremony
reduces reuse without improving safety.
