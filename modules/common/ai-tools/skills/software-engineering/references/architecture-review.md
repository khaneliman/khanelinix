# Proposed Standalone Software Architecture Review

Use for a design proposal or ADR before implementation and outside review of a
commit, PR, or diff. Use repository evaluation for existing architecture. Git
artifacts use `$git-toolkit` adversarial review, which may import these lenses.
Both follow the review contract in the `premise-review` method of
`engineering-principles`; this procedure adds architecture lenses, not another
finding format or verdict.

## Procedure

1. Resolve review target, requirements, intended behavior, affected
   stakeholders, and excluded concerns.
2. Run the premise gate from the `premise-review` method in
   `engineering-principles`: confirm the demonstrated problem, existing
   capability, and native abstraction before challenging proposed structure.
3. Recover contract from requirements, contributor canon, public interfaces,
   schemas, tests, and current behavior. Call out contradictions.
4. Trace proposed flows end to end. Check normal path, boundary inputs, errors,
   cancellation, cleanup, retries, and recovery.
5. Challenge state model: invalid states, invariant ownership, transition
   atomicity, aliases, concurrent writers, persistence, migration, and rollback.
6. Challenge boundaries: dependency direction, authority, information exposure,
   change propagation, failure containment, and operational ownership.
7. Check compatibility and rollout across callers, stored data, protocols,
   configuration, deployment ordering, and mixed-version operation when
   relevant.
8. Evaluate proposed validation by contract and failure mode, not changed-line
   coverage. Run read-only or repository-native checks when they avoid external
   mutation; otherwise state evidence gap.
9. Apply root responsibility lens at its concrete depth escalators.

## Finding Standard

Report finding only when evidence shows plausible failure, violated requirement,
uncontained risk, or material maintenance/operation cost. Write each finding in
the contract's conventional-comment format. For a design, its location is the
design premise or section, and its failure names:

- confidence in the conclusion;
- triggering scenario;
- observable impact and affected stakeholder;
- why proposed or existing guard does not contain it;
- smallest viable correction or decision needed.

Decide blocking status from impact, reach, likelihood, detectability, and
recovery. Do not rank findings based only on pattern labels. A code smell, SOLID
violation, mutable state, missing abstraction, or absent approval gate is not a
finding without demonstrated consequence.

## Output

1. Findings first, blocking findings first.
2. Open questions or assumptions that could change verdict.
3. The contract verdict with a short architecture summary: requirement fit,
   change readiness, and operational risk.
4. Verification performed and gaps.

If no findings survive validation, say so directly and state residual risks or
untested surfaces. Do not pad review with style preferences.
