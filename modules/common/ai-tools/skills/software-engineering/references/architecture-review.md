# Proposed Standalone Software Architecture Review

Use for a design proposal or ADR before implementation and outside review of a
commit, PR, or diff. Use repository evaluation for existing architecture. Git
artifacts always use `$git-toolkit` adversarial review; that workflow may import
these lenses while retaining its clean-room, finding, and verdict contracts.

## Procedure

1. Resolve review target, requirements, intended behavior, affected
   stakeholders, and excluded concerns.
2. Recover contract from requirements, contributor canon, public interfaces,
   schemas, tests, and current behavior. Call out contradictions.
3. Trace proposed flows end to end. Check normal path, boundary inputs, errors,
   cancellation, cleanup, retries, and recovery.
4. Challenge state model: invalid states, invariant ownership, transition
   atomicity, aliases, concurrent writers, persistence, migration, and rollback.
5. Challenge boundaries: dependency direction, authority, information exposure,
   change propagation, failure containment, and operational ownership.
6. Check compatibility and rollout across callers, stored data, protocols,
   configuration, deployment ordering, and mixed-version operation when
   relevant.
7. Evaluate proposed validation by contract and failure mode, not changed-line
   coverage. Run read-only or repository-native checks when they avoid external
   mutation; otherwise state evidence gap.
8. Apply root responsibility lens at its concrete depth escalators.

## Finding Standard

Report finding only when evidence shows plausible failure, violated requirement,
uncontained risk, or material maintenance/operation cost. Each finding includes:

- severity and confidence;
- concrete design premise or current location;
- triggering scenario;
- observable impact and affected stakeholder;
- why proposed or existing guard does not contain it;
- smallest viable correction or decision needed.

Rank severity from impact, reach, likelihood, detectability, and recovery—not
pattern labels. Code smell, SOLID violation, mutable state, missing abstraction,
or absent approval gate is not finding without demonstrated consequence.

## Output

1. Findings first, highest severity first.
2. Open questions or assumptions that could change verdict.
3. Short architecture verdict: requirement fit, change readiness, and
   operational risk.
4. Verification performed and gaps.

If no findings survive validation, say so directly and state residual risks or
untested surfaces. Do not pad review with style preferences.
