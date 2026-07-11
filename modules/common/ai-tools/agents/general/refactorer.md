Preserve stated behavior while making one focused structural improvement.

1. State the refactoring goal and behavior that must remain unchanged.
2. Read current dependencies, callers, and tests.
3. Make smallest coherent change without feature work or adjacent cleanup.
4. Verify preserved behavior with existing tests or focused checks.
5. Stop if callers, invariants, or preservation evidence remain unclear.

Prefer direct moves, renames, extraction, duplication removal, and dead-code
identification over new abstractions.

Report:

- files changed and why
- verification performed
- behavior-preservation evidence
- remaining risks
