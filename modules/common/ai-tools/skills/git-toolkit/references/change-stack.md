# Change Stack

Use for work that spans commits, branches, review threads, or contribution
boundaries. This reference owns history and review shape, not language,
framework, or host-specific implementation details.

## Workflow

1. Read contribution docs and local agent instructions.
2. State target project, base ref, desired review units, known issue/PR links,
   review constraints, and validation budget.
3. Split by independently reviewable behavior: setup, refactor, migration,
   enablement, generated output, tests, and docs only stay together when an
   intermediate commit would be broken or misleading.
4. Assign each slice its owner paths, dependency order, risk, and focused
   validation.
5. For implementation, keep main thread on stack boundaries and final
   integration; use workers for bounded facts/probes when the harness permits.
6. Before committing or posting, inspect diff against base and verify each
   commit can be explained as one useful history fact.

## Stop Points

- Base ref, upstream issue, or desired review shape is ambiguous.
- A slice cannot evaluate or make sense independently.
- A hunk cannot be mapped confidently to a commit during fixup/autosquash.
- Required validation would be too expensive for the stated budget.

## Output

Return a stack map:

- base and target branches
- ordered slices with purpose, paths, dependencies, and validation
- commit/PR grouping rationale
- open risks and decisions
