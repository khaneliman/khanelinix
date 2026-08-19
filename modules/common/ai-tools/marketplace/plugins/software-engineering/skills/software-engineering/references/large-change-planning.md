# Large-Change Planning

Produce a feature, refactor, migration, or technical-debt plan another engineer
can implement and verify without rediscovering core behavior.

## Procedure

1. Frame user or operator outcome, representative use cases, non-goals,
   constraints, compatibility promises, and acceptance evidence.
2. Trace current end-to-end behavior and identify smallest observable delta.
   Name affected interfaces, owners, state, and external systems.
3. Specify proposed contract:
   - inputs, outputs, errors, and side effects;
   - permissions and trust boundaries;
   - ordering, latency, resource, and compatibility guarantees;
   - cancellation, retry, and idempotency semantics where applicable.
4. Model state and lifecycle. Define valid states, invariants, transitions,
   persistence, migration, concurrent access, cleanup, and recovery.
5. Choose boundaries from domain ownership, independent change, authority,
   failure containment, and test seams. Reuse existing abstractions unless they
   violate required contract or force unrelated change.
6. Compare materially different options, including minimal extension when
   viable. State benefit, cost, irreversible commitment, and trigger for
   revisiting.
7. Slice chosen design into end-to-end increments. Each increment should have
   owned files/components, prerequisites, observable result, focused tests, and
   safe integration state.
8. Define migration, rollout, observability, rollback, and removal of temporary
   compatibility paths before implementation begins.

Apply root engineering lenses to proposed delta. Keep only risks supported by
requirements, repository evidence, or credible failure and change scenarios.

## Validation Strategy

Map every important guarantee or risk to evidence:

- contract tests for public behavior and compatibility;
- unit/property/model tests for invariants and transition spaces;
- integration tests for boundaries and adapters;
- concurrency, fault-injection, or recovery tests for credible failure modes;
- performance measurements only against explicit budget or regression concern;
- staged rollout and production signals for behavior tests cannot prove.

Use repository-native commands. Identify checks that cannot run locally and how
they will be read back.

## Output

1. Outcome, non-goals, assumptions, and acceptance criteria.
2. Current flow and proposed delta.
3. Chosen design plus contracts, invariants, boundaries, and failure model.
4. Alternatives and decision rationale.
5. Ordered implementation increments with file/component ownership,
   dependencies, tests, and completion evidence.
6. Migration, rollout, rollback, observability, risks, and unresolved questions.

Do not invent file paths or APIs before inspecting repository. Do not front-load
generic infrastructure into first increment unless required by contract.
