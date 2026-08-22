# Task Shapes

Pick one shape in the shape phase. The shape sets ground depth, verification
target, and the done signal. It does not replace the domain skill that owns the
method.

Investigation is a phase inside every shape, not a shape of its own. When the
user wants an explanation and no mutation, leave this skill and use `how` or
`why`.

## Bug Fix

- Goal: restore intended behavior at the true cause.
- Ground: reproduce the failure first. Capture the failing signal before any
  edit. Use `diagnosing-bugs` when the cause needs a minimal reproduction and
  falsifiable probes. Use `why` when the code looks deliberate or the
  regression has history.
- Shape: fix the cause, not the symptom. Keep the diff at the smallest scope
  that removes the cause. Apply `fix-root-causes` from `engineering-principles`.
- Verify: rerun the original failing signal, then the nearest regression
  surface.
- Done: the captured failure now passes, and no adjacent behavior changed.

## Feature

- Goal: add behavior that did not exist.
- Ground: read the surrounding module, its contracts, and its idioms.
- Shape: name the data model and choose types, signatures, and placement before
  code. Apply `model-the-domain`, `boundary-discipline`, and
  `type-system-discipline` from `engineering-principles`. Use `architect` for a
  non-trivial feature or a boundary crossing. Use `tdd` only when the user
  requests TDD or test-first work.
- Verify: exercise the new path and one existing path that shares its
  dependencies. Use `verification-harness` to audit or propose when no reliable
  check covers the observable behavior. Create it only with explicit authority.
- Done: the new behavior works on the real surface, and existing callers still
  work.

## Refactor

- Goal: change structure while behavior stays identical.
- Ground: find every caller and every observable contract before editing.
- Shape: pin current behavior, subtract dead weight, then sequence mechanical
  steps so each step keeps the tree working. Apply `subtract-before-you-add` and
  `minimize-reader-load` from `engineering-principles`.
- Verify: prove behavior parity. Use `verification-harness` to audit or propose
  when the existing parity surface is missing or unreliable. Create it only with
  explicit authority. Use `blast-radius` when call reach is unclear.
- Done: structure improved, and no observable behavior moved.

## Prototype

- Goal: learn whether an approach works.
- Ground: state the question the prototype answers. Keep ground shallow.
- Shape: build the smallest artifact that answers the question. Accept throwaway
  quality inside the prototype boundary.
- Verify: check the answer, not the polish.
- Done: the question is answered, and the report states what is throwaway and
  what could be kept.

## Evaluation

- Goal: compare candidate options and choose one.
- Ground: define the criteria and the fixed comparison surface first. Use
  `research` when the comparison requires external primary-source facts.
- Shape: run each candidate against identical criteria. Use `arena` for
  competing artifacts. Use `interrogate` when the choice is contested or high
  stakes.
- Verify: confirm the evidence supports the ranking and record what would change
  it.
- Done: one option is chosen, with the tradeoff and the reversal condition
  written down.

## Attribution

These shape distinctions are adapted from pstack. Prose is original. Upstream
terms are in [LICENSE](../LICENSE).
