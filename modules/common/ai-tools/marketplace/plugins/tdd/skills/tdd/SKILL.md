---
name: tdd
description: "Red-green-refactor Implement method inside a caller-owned lifecycle for explicit TDD or test-first requests. Requires red evidence, minimal green implementation, and rerun validation."
license: Complete terms in LICENSES/
---

# Test-Driven Development

Use this method when implementing features or bug fixes test-first. Test-driven
development executes a red-green-refactor loop across observable behavior
boundaries.

This skill is a narrow implementation method. It does not own lifecycle
planning, repository design review, or external handoff.

## Execution Rules

Execute vertical slices. Complete one seam, one failing test, and one minimal
implementation per cycle. Do not write tests in bulk before implementation.

1. **Identify the behavior seam.** Select the public interface that exposes the
   behavior. Avoid testing private functions or internal state. See
   [references/test-quality.md](references/test-quality.md) for test quality
   rules.
2. **Write the failing test.** Write one focused test for the intended behavior.
   Avoid tautological assertions and implementation coupling. Use mocks only for
   external system boundaries per
   [references/mocking.md](references/mocking.md).
3. **Execute the test to verify failure.** Run the test suite on the new test.
   Confirm the test fails for the expected reason. Capture the failure evidence.
4. **Implement the minimal fix.** Write only enough production code to pass the
   test. Do not add speculative capabilities or unneeded abstractions.
5. **Rerun the test.** Execute the test to verify green status. Run adjacent
   tests to verify no regressions.
6. **Apply bounded refactoring.** Clean up duplication and structure while
   keeping tests green. Re-run tests after each small cleanup.

## When Tests Are Impractical

Skip test creation when tests require broad harness setup, brittle mocks, slow
end-to-end infrastructure, or production-only state.

When skipping a test:

- State why a unit or integration test is impractical.
- Run the closest executable check, such as a script, reproduction command, or
  log verification.
- Capture the output before and after the change.

## Output Evidence

Report the following evidence to the caller:

- Behavior seam and test location.
- Red phase failure output with the failure reason.
- Green phase success output and execution duration.
- Adjacent test verification results.
- Bounded refactoring changes applied.

## Attribution

Adapted from upstream pstack and Matt Pocock TDD skills. See
[LICENSES/LICENSE-pstack.txt](LICENSES/LICENSE-pstack.txt) and
[LICENSES/LICENSE-matt-pocock.txt](LICENSES/LICENSE-matt-pocock.txt).
