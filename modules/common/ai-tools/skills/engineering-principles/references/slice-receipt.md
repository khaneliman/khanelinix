# Exact Slice Evidence

Use when high risk, concurrent ownership, or an explicit delivery contract
requires binding checks and review to exact content. Ordinary atomic commits
can record the diff, check results, review verdict, and commit SHA instead.

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

