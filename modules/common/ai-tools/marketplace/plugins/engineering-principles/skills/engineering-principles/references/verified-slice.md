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
green and useful without the next slice. Record red evidence before the fix,
but do not create a knowingly broken commit unless repository policy explicitly
permits that stack shape.

## Authority Modes

Treat authority as capabilities, not as a workflow side effect.

- `workspace-only`: edit, verify, and review. Do not stage or commit.
- `local-commit`: stage exact slice changes and create the accepted local
  commit. This means ordinary advancement of the currently checked-out local
  branch only. It does not authorize branch creation, branch deletion, branch
  reset, force-moving a branch, or another ref mutation.
- Remote issue, review, push, merge, release, deploy, and cutover grants remain
  separate. A local-commit grant implies none of them.

Without local-commit authority, complete one reviewed slice and hand off its
exact patch. Before another slice, obtain commit authority or preserve each
candidate in a separate worktree with explicit path ownership or an exact patch
artifact. Do not stack several uncommitted slices in one mutable tree and call
them reversible.

## Loop

1. **Ground.** Confirm base, existing scoped changes, owner, authority, outcome,
   and predicate. Stop on unknown overlap.
2. **Baseline.** Run the predicate before writes. Capture the expected red or
   current green behavior. If the check cannot detect the outcome, repair the
   verification contract before implementation.
3. **Implement.** Make the smallest change that can satisfy the predicate. Keep
   one write owner for the scope.
4. **Verify.** Run the focused predicate on the real artifact. Run the nearest
   regression surface for normal risk. Add reach and integration checks for
   high risk.
5. **Review.** Apply the proportional review gate below. The lifecycle owner
   validates reviewer findings against code and evidence.
6. **Correct.** Apply accepted completion-blocking findings once. Re-run every
   invalidated check, then allow one re-review.
7. **Prepare candidate.** With local-commit authority, stage only slice changes
   and inspect the staged diff. Without authority, materialize the exact handoff
   patch. If slice changes cannot be separated from pre-existing work, do not
   commit.
8. **Bind evidence.** Create the pre-commit receipt against the unchanged base
   and exact staged diff or handoff patch.
9. **Commit or hand off.** Create one scoped Conventional Commit, or return the
   exact patch and stop before another shared-tree slice.
10. **Confirm occurrence.** After commit, hash the new commit with the receipt
    canonicalization. The committed content digest must equal the receipt
    content digest. Record the occurrence only after equality.
11. **Advance.** Start the next slice only after this slice is verified and its
    rollback boundary is durable.

Use `VERIFIED`, `NOT_VERIFIED`, or `INCONCLUSIVE` as the evidence verdict.
Only `VERIFIED` pre-commit evidence can commit. Only a confirmed occurrence can
advance. A command that did not run cannot pass.

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
After one correction and one re-review, stop if an accepted blocking finding
remains.

## Pre-Commit Receipt

Create the receipt after candidate preparation and immediately before commit or
handoff:

```text
slice_id
base_commit
base_state_digest
content_digest
candidate_form
scope
authority
predicate
checks_and_results
review_identity_and_verdict
accepted_findings
evidence_verdict
```

`base_state_digest` identifies any pre-existing scoped work that the slice must
preserve and exclude from its commit. `content_digest` is the SHA-256 digest of
the exact staged diff, worktree diff, or handoff patch, including new files. Use
`../scripts/content_digest.py --staged` for the staged form,
`../scripts/content_digest.py --worktree [BASE]` for the workspace-only form,
and `../scripts/content_digest.py --committed COMMIT` for the committed form.
`--worktree` defaults BASE to `HEAD`. It reads the worktree without staging or
committing. `candidate_form` `staged` selects `--staged`. `candidate_form`
`patch` selects `--worktree`. The tool sorts length-prefixed side, path, mode,
blob OID, and raw blob-content records. The side is `A` for a post-image blob
and `D` for a pre-image blob. A `D` record carries the raw leading colon of Git
raw output in its mode field. The tool uses Git plumbing with disabled external
diff, text conversion, and locale configuration. It emits path bytes without
requiring UTF-8. Every mode fails when its selected diff contains zero changes.
Record the command and version. If candidate content changes, invalidate
verification and review evidence that depended on the old digest.

## Commit Occurrence

After a successful local commit, record:

```text
slice_id
commit_sha
parent_sha
receipt_content_digest
committed_content_digest
digest_match
committed_paths
```

The commit SHA identifies the delivered occurrence. Pass that single commit SHA
to the tool with the same command and canonicalization as the receipt. The tool
derives the first parent and digests that diff. A merge commit therefore digests
the first-parent diff only. If `committed_content_digest` differs from
`receipt_content_digest`, mark the occurrence `NOT_VERIFIED`. Inspect hook or
staging changes, then re-run invalidated checks and review before correction.

A content digest proves changed-path blob-content identity under one
canonicalization. It does not prove patch-byte identity, and it does not prove
semantic equivalence after history changes. A rebase, parent rewrite, or changed
dependency base invalidates integration evidence. Re-run those checks before
claiming the rewritten occurrence is ready.

## Failure and Recovery

- If the predicate stays red, correct or revert only the current slice.
- If evidence is inconclusive, do not commit or advance.
- If scope overlaps unfamiliar work, stop and resolve ownership first.
- If a reviewer finds a larger requirement, return it to the lifecycle owner as
  a new slice or scope decision.
- If commit fails after evidence binding, preserve the receipt and candidate
  patch. Retry only while base and content digests still match.
