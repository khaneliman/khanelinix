# Verified Slice

Use this method inside a lifecycle owner. It does not select the task workflow,
own architecture, or grant authority. It turns one planned unit into a checked,
reviewable, and reversible result.

## Slice Contract

Before writes, record these fields:

- `slice_id`: stable identifier inside the current task or program.
- `outcome`: one observable result, not an activity list.
- `base_commit`: exact starting commit SHA.
- `scope`: exact paths and boundaries the slice may change.
- `authority`: granted capabilities for this slice.
- `risk`: `trivial`, `normal`, or `high`.
- `predicate`: check that fails when the outcome is absent or wrong.
- `rollback`: how to remove this slice without removing later independent work.

Shrink a slice when it cannot satisfy one predicate, one review decision, and
one rollback boundary. A scaffold can be its own slice only when it remains
green and useful without the next slice. TDD is opt-in: record red evidence
before implementation when the user requests TDD or test-first work. Otherwise
use proportionate existing checks or direct inspection; do not invent tests to
fill the contract. Do not commit knowingly broken code unless repository policy
explicitly permits that stack shape.

## Authority Modes

Treat authority as capabilities, not as a workflow side effect. A current
request or standing user policy can grant local-commit authority; do not require
a special phrase or a fresh grant for every slice.

- `workspace-only`: edit, verify, and review. Do not stage or commit.
- `local-commit`: stage exact slice changes and create the accepted local
  commit. This means ordinary advancement of the currently checked-out local
  branch only. It does not authorize branch creation, branch deletion, branch
  reset, force-moving a branch, or another ref mutation.
- Remote issue, review, push, merge, release, deploy, and cutover grants remain
  separate. A local-commit grant implies none of them.

With local-commit authority, commit each verified slice before advancing.
Without it, preserve each candidate in a separate worktree with explicit path
ownership or an exact patch artifact before the next slice. Continue already
authorized work without adding a commit-approval checkpoint. Do not call a pile
of unrecorded shared-tree edits a durable rollback boundary.

## Loop

1. **Ground.** Confirm base, existing scoped changes, owner, authority, outcome,
   and predicate. Stop on unknown overlap.
2. **Baseline.** Capture relevant pre-change behavior when it helps establish
   correctness. Require a failing test first only for opted-in TDD. Choose
   checks that can detect the outcome without unnecessary test scaffolding.
3. **Implement.** Make the smallest change that can satisfy the predicate. Keep
   one write owner for the scope.
4. **Verify.** Run the focused predicate on the real artifact. Run the nearest
   regression surface for normal risk. Add reach and integration checks for
   high risk.
5. **Review.** Apply the proportional review gate below. The lifecycle owner
   validates reviewer findings against code and evidence.
6. **Correct.** Resolve accepted blockers, rerun invalidated checks, and request
   focused re-review. Continue while making progress; re-ground repeated unchanged
   failures. Stop for a concrete blocker or a required user decision.
7. **Prepare candidate.** With local-commit authority, stage only slice changes
   and inspect the staged diff. Without authority, materialize the exact handoff
   patch. If slice changes cannot be separated from pre-existing work, do not
   commit.
8. **Bind evidence.** Record the scoped diff, checks, and review. Use an exact
   receipt only when the Exact Content Evidence gate below requires it.
9. **Commit or preserve.** Create one scoped Conventional Commit when authorized;
   otherwise preserve the exact patch or isolated worktree before advancing.
10. **Confirm occurrence.** For a commit, inspect its SHA and changed paths. When a
    receipt is required, verify the committed content digest against it. Recheck
    any content changed by hooks before claiming completion.
11. **Advance.** Start the next slice only after this slice is verified and its
    rollback boundary is durable.

Use `VERIFIED`, `NOT_VERIFIED`, or `INCONCLUSIVE` as the evidence verdict.
Only `VERIFIED` evidence can advance. A committed slice needs a confirmed
occurrence; a workspace-only slice needs its verified, preserved candidate.
A command that did not run cannot pass.

## Proportional Review

- **Trivial:** focused verification is required. Fresh review is optional. The
  pre-commit receipt and commit occurrence records are optional. When the slice
  skips those records, it reports the focused verification evidence directly.
- **Normal:** focused and regression checks are required. One fresh reviewer is
  required.
- **High:** focused, regression, reach, and integration checks are required.
  Independent review is required. Use adversarial review when risk is contested
  or one reviewer cannot cover the relevant boundaries.

A reviewer must not be the slice writer. Suggestions do not expand slice scope.
Accepted blockers prevent completion, not further authorized correction. Keep
review read-only and correction separate; do not re-review cleared concerns
without changed evidence.

## Exact Content Evidence

For high risk, concurrent ownership, or explicit delivery provenance, read
[slice-receipt.md](slice-receipt.md) and bind review to the exact candidate.
Otherwise record the scoped diff, checks, reviewer verdict, and commit SHA or
preserved patch. Do not create receipts solely to satisfy routine ceremony.

## Failure and Recovery

- If the predicate stays red, correct or revert only the current slice.
- If evidence is inconclusive, do not commit or advance.
- If scope overlaps unfamiliar work, stop and resolve ownership first.
- If a reviewer finds a larger requirement, return it to the lifecycle owner as
  a new slice or scope decision.
- If commit fails, preserve the candidate and existing evidence. Retry only
  while the reviewed base and content remain unchanged; when using an exact
  receipt, compare its digests.
