# Pull Request Review Authoring

Use for high-signal review and explicit inspection or mutation of GitHub reviews
owned by current actor. Use [pr-feedback.md](pr-feedback.md) for existing review
comments.

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
6. Return draft findings by default. Inspect, create, update, or delete a review
   only when user explicitly requests it.

Never submit pending review, approve, request changes, push, or edit source.
Leave final publication to user in GitHub UI.

## Review Operations

Inspect reviews before each write. Default output contains all reviews owned by
current actor. Use `--all-reviews` only when other actors provide needed
context:

```bash
python "<path-to-skill>/scripts/review_draft.py" inspect \
  --repo "OWNER/REPO" --pr "NUMBER_OR_URL" --include-bodies
```

Inspection returns GraphQL `id` and REST `database_id` values for reviews and
inline comments. Use these GitHub identities for updates and deletions. Do not
add hidden ownership markers or other tool-specific text to public prose.

Create one pending review from ordinary prose and optional inline comments. Omit
`body` for an inline-only review:

```json
{
  "expected_head_sha": "FULL_HEAD_SHA",
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

Update any current-actor review summary or comment that GitHub permits. Identify
the review and each comment explicitly:

```json
{
  "review_id": "PRR_GRAPHQL_OR_DATABASE_ID",
  "body": "Updated review summary.",
  "comments": [
    {
      "id": "PRRC_GRAPHQL_ID",
      "body": "Updated inline comment."
    }
  ]
}
```

Delete a current-actor pending review by review ID:

```json
{ "review_id": "PRR_GRAPHQL_OR_DATABASE_ID" }
```

Delete current-actor review comments without deleting their review:

```json
{
  "review_id": "PRR_GRAPHQL_OR_DATABASE_ID",
  "comments": [{ "database_id": "COMMENT_DATABASE_ID" }]
}
```

Run `create`, `update`, or `delete` without `--apply` first. Review exact
planned IDs and operations. Add `--apply` only when user explicitly requested
that write. Helpers refresh actor ownership and selected IDs before mutation,
then read back exact bodies or absence. GitHub permits review-summary updates
after submission but permits whole-review deletion only while review is pending.
Submitted inline comments can still be updated or deleted.

Never infer ownership from prose. Never select update or delete targets by body
text or diff anchor. Use `id` for a GraphQL node ID or `database_id` for a
numeric comment ID. The helper rejects submission events and cannot approve,
request changes, comment-submit, or dismiss reviews.

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
