# Scrap Signals

Implementation friction that condemns a sketch is a pattern, not a single
instance. Tells:

- The same shape of workaround appears repeatedly across unrelated code.
- Multiple unrelated edge cases each need a special-case branch.
- Types need escape hatches to compile, such as `any`, casts, or optional fields
  that are always set in practice.
- The "we need a lock" reflex appears when the sketch said the state was not
  shared.
- Callers must learn the abstraction's internal rules to use it.
- Two or more independent Phase D deviations share the same shape. Surfacing
  deviations is Phase D's job; a repeated pattern of them is Phase E's trigger.

Use judgment. A few edge cases do not condemn an architecture. Some problems are
legitimately complex; complexity in the data is not complexity in the design.
The rewrite trigger is repeated friction of the same shape, not a single hard
case.
