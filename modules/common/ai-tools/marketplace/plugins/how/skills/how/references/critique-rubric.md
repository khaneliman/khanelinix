# Architectural Critique Rubric

Review through whichever lenses are relevant. Not every lens applies to every
subsystem.

## Abstraction Fit

Are the abstractions pulling their weight?

- Does each abstraction represent a real concept, or is it an indirection layer
  added "in case we need it"?
- Are the boundaries in the right place? Do they separate things that change
  independently?
- Is there accidental coupling where components share implementation details
  they should not need to know about?
- Is business logic entangled with framework wiring, or cleanly separated?

Over-abstraction is as much a problem as under-abstraction. A flat, simple
design is fine when the domain is simple.

## Data Model

Do the data structures fit the actual usage patterns?

- Are the data models designed for how the code accesses data, or for how
  someone modeled it conceptually?
- Are there impedance mismatches, places where code constantly reshapes data
  because the model does not match the access pattern?
- Do the types match reality? Do they represent what data looks like at runtime,
  or claim more structure than exists?

## Boundary Discipline

Are system boundaries clean and well-placed?

- Is validation concentrated at entry points, or scattered through internal
  code?
- Are errors handled at boundaries and propagated cleanly, or caught and
  re-thrown at every layer?
- Does data cross boundaries in well-typed shapes, or as bags of optional
  fields?
- Could this subsystem be tested in isolation, or does it require the entire
  system to run?

## Evolution Readiness

How well will this architecture handle likely changes?

- If the most probable next requirement landed tomorrow, how much would change:
  one file or everything?
- Are there hardcoded assumptions that would need to be relaxed?
- Is the design bolted on, integrated as an afterthought, or integrated so it
  looks like it was always part of the plan?
- Are legacy paths preserved for compatibility that no one depends on?

Do not penalize the design for not handling hypothetical changes. Focus on
changes that are plausible given the codebase's trajectory.

## Complexity vs. Value

Is the complexity budget spent wisely?

- Is complexity concentrated in the parts that need it, such as core logic and
  tricky invariants, or in accidental places such as boilerplate, unnecessary
  indirection, and configuration?
- Are there simpler ways to achieve the same behavior?
- Does every component earn its existence, or are there vestigial pieces from an
  earlier design?

## Consistency

Does this subsystem follow the patterns established elsewhere in the codebase?

- Are similar problems solved the same way here as elsewhere, or does this area
  invent its own patterns?
- If the patterns differ, is there a good reason, or did the area evolve
  independently?
- Inconsistency is not automatically bad. Unexplained inconsistency is a
  maintenance burden.
