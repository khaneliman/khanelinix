# Phase Handoff

Keep one current acceptance summary in the caller's existing task notes or
conversation. Persist it when recovery or handoff needs it; do not create a spec,
ticket set, or extra approval checkpoint solely to satisfy this method.

## Ground to Shape

Name the outcome, current behavior, constraints, non-goals, and observable
acceptance evidence. Separate settled requirements from assumptions and open
product choices. A bounded request may need only a few lines.

Use `requirements-interview` for unresolved material choices after discovering
available facts. Reuse its decision summary; do not restart an interview when
requirements are already clear. Keep `to-spec` and `to-tickets` as explicit
exports when the user wants those durable artifacts.

## Shape to Implement

Name the affected interface or state boundary, the chosen design, and the
verification surface. Use the cheapest artifact that resolves uncertainty:
pseudocode/types, an ownership/state diagram, a runnable mockup, or visual
variants. An obvious mechanical change does not need a design artifact.

Choose testing deliberately. TDD remains opt-in. Existing regression tests,
parity checks, builds/evaluations, or a focused manual probe may provide the
appropriate evidence. Do not manufacture tests for low-impact edits or require
broad harness setup when a narrower check establishes the result.

## Verify to Review and Handoff

Map acceptance criteria to observed results. Reuse current checks rather than
rerunning them for another phase's ceremony. Record meaningful gaps without
claiming unexecuted checks passed.

Review correctness and requirements fit; resolve accepted blockers within scope.
Update only the design, assumptions, and checks invalidated by new evidence.
Record each verified slice's commit SHA under local-commit authority, or its
preserved patch when workspace-only. Keep remote delivery separately authorized.
