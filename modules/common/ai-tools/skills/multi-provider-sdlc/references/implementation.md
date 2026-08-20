# Implementation

1. Read contributor canon and confirm the caller-supplied baseline, dirty paths,
   risk, and implementation contract.
2. Dispatch bounded write batches with exact paths, constraints, validation, and
   exit criteria. Split only disjoint write scopes; never duplicate
   implementations for provider diversity.
3. Inspect returned changes. Preserve unrelated work and reject scope expansion.
4. Return changed files, focused validation, assumptions, and residual risk to
   the lifecycle owner. Do not start validation or review phases.

Use one best-fit write route per batch. Opus may implement; read-only behavior
is a phase assignment for deliberation and review, not a model-level
restriction.
