# Pull Request Review Authoring

Use for a high-signal review and a draft or explicitly requested pending GitHub
review. Use [pr-feedback.md](pr-feedback.md) for existing review comments.

## Workflow

1. Resolve one target and capture bounded metadata:

   ```bash
   python "<path-to-skill>/scripts/pr_snapshot.py" \
     --repo "OWNER/REPO" --pr "NUMBER_OR_URL"
   ```

   Snapshot defaults to at most 200 files and 100 commits. Check
   `completeness.files` and `completeness.commits` before treating scope as
   exhaustive. Increase `--max-files`/`--max-commits`, or use `0` to fetch
   through GitHub's API hard cap.

2. Stop for closed or draft pull requests, or generated/dependency-only changes
   with no reviewable code.
3. Read contributor guidance, PR template, root and changed-path instructions,
   and directly relevant documentation.
4. Review only diff plus necessary local context. Load matching language/domain
   skill before judging implementation details.
5. Validate each finding against changed code and repository policy.
6. Return draft findings by default. Create or update a pending review only when
   user explicitly requests it.

Never submit pending review, approve, request changes, push, or edit source.
Leave final publication to user in GitHub UI.

## Pending Review Helper

Inspect pending and marked reviews before any write:

```bash
python "<path-to-skill>/scripts/review_draft.py" inspect \
  --repo "OWNER/REPO" --pr "NUMBER_OR_URL" --include-bodies
```

Create input:

```json
{
  "expected_head_sha": "FULL_HEAD_SHA",
  "body": "<!-- ai-tools:review-pr -->\nReview context.",
  "comments": [
    {
      "path": "path/to/file",
      "start_line": 10,
      "line": 12,
      "side": "RIGHT",
      "body": "issue (blocking): describe validated defect"
    }
  ]
}
```

Plan first; add `--apply` only for explicitly requested pending-review creation:

```bash
python "<path-to-skill>/scripts/review_draft.py" create \
  --repo "OWNER/REPO" --pr "NUMBER_OR_URL" --input review.json
```

Update input identifies owned draft comments by GraphQL `id`, REST
`database_id`, or exact `path`/`start_line`/`line`, and supplies replacement
`body`. Review `body` and `review_id` are optional. Plan then apply with the
same command shape using `update`.

Helper enforces exact head SHA, current-actor ownership, pending state, one
marker, and current diff anchors. It rejects unknown fields and has no review
submission event surface.

After `--apply`, inspect `applied`, `mutation`, and `verification.status`.
`applied: true` with `unverified` means GitHub accepted the write but readback
could not prove every requested anchor; inspect current draft and do not retry
blindly. `partial` lists operations already applied before a later update
failed. Only `verified` proves post-write state and exact anchors.

## High-Signal Review Policy

Flag only highly likely defects:

- syntax, type, compile, or unresolved-reference failures
- logic that definitely produces wrong behavior
- clear security or data-loss defects in changed code
- clear instruction-file violations scoped to changed file
- clear contribution-policy violations: commit message, atomicity, required
  tests/checks, licensing, or secrets

Do not flag style, subjective quality, pre-existing problems, speculative edge
cases, duplicates, or normal linter findings unless repo instructions require.
Validate each issue against diff and relevant local instructions.

Do not re-run green CI checks merely to restate them. Judge whether checks cover
changed behavior; missing coverage can be a finding when repository policy or
risk requires it.

## Review Writing

- Keep review body to outcome, confidence, and global context. Do not duplicate
  inline findings.
- Write one inline comment per unique issue: problem, reason, next step.
- Keep each discussion to 1-3 short sentences unless evidence requires more.
- Use suggestion blocks only when they fully fix the selected line range.
- Cite local instructions for compliance findings and concrete commit SHAs for
  code links.

Format inline comments as:

```markdown
<label> [decorations]: <subject>

[necessary evidence, reasoning, and next step]
```

Use `issue`, `suggestion`, `question`, `nitpick`, `note`, `praise`, or `todo`.
Use `(blocking)` only for high-signal defects; otherwise use `(non-blocking)` or
omit decoration. Keep one primary label.

No-issues comment when requested:

```markdown
## Code review

No issues found. Checked for bugs and repository instruction/contribution
compliance.
```
