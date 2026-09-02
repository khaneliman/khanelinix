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
4. Before reviewing code, load every corresponding specialist skill for each
   changed language or domain, such as `rust-toolkit`,
   `typescript-best-practices`, or `writing-nix`. This is a hard precondition.
   If any changed code lacks a matching skill in the supplied lane, state the
   coverage limitation. Return a blocked review.
5. Run the premise gate from the `premise-review` method in
   `engineering-principles` before reading the diff for defects. Record each
   premise concern as a conventional comment with evidence from the issue, the
   PR body, and the repository. When the gate fails, draft a review that
   recommends redesign or closure with the native abstraction or existing
   capability named, even when every check is green.
6. Review only diff plus necessary local context after the specialist skill is
   loaded.
7. Revalidate each finding against the current PR head, changed code, and
   repository policy before drafting or revising it.
8. Return draft findings by default. Inspect, create, update, or delete a review
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

Update a current-actor review summary or comment only when GitHub permits it.
For a pending review mutation, inspect the exact review and comment IDs again.
Confirm the review is pending and owned by the current actor. Identify the
review and each comment explicitly:

```json
{
  "review_id": "PRR_GRAPHQL_OR_DATABASE_ID",
  "expected_head_sha": "FULL_HEAD_SHA",
  "expected_review_state": "PENDING",
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

Run `create`, `update`, or `delete` without `--apply` first and preview every
planned mutation, including its exact IDs and replacement body. Add `--apply`
only when the user explicitly requested that write. Helpers refresh actor
ownership and selected IDs before mutation, then read back exact bodies or
absence. For a pending-review update, include `expected_head_sha` and
`expected_review_state: "PENDING"`. The helper validates both during preview and
again immediately before mutation. This guard is optional for separately
authorized submitted-review updates. When revising a pending review, select only
the exact review owned by the current actor. Never submit it. GitHub permits
review-summary updates after submission but permits whole-review deletion only
while a review is pending. Submitted inline comments can still be updated or
deleted when explicitly requested.

Never infer ownership from prose. Never select update or delete targets by body
text or diff anchor. Use `id` for a GraphQL node ID or `database_id` for a
numeric comment ID. The helper rejects submission events and cannot approve,
request changes, comment-submit, or dismiss reviews.

## High-Signal Review Policy

Flag only highly likely defects:

- a failed premise gate: no demonstrated problem, inaccurate issue fit, an
  existing capability, a parallel option or data model where a native
  abstraction exists, the wrong public API boundary, removable diff, or bundled
  unrelated changes
- syntax, type, compile, or unresolved-reference failures
- logic that produces incorrect behavior for a validated input or state
- clear security or data-loss defects in changed code
- clear instruction-file violations scoped to changed file
- clear contribution-policy violations: commit message, atomicity, required
  tests/checks, licensing, or secrets

Do not flag style, subjective quality, pre-existing problems, speculative edge
cases, duplicates, or normal linter findings unless repo instructions require.
Validate each issue against diff and relevant local instructions.

Do not re-run green CI checks merely to restate them. Green CI is supporting
evidence, not the purpose of review. Judge whether checks cover changed
behavior; missing coverage can be a finding when repository policy or risk
requires it.

## Review Writing

- Keep review body to outcome, confidence, and global context. Do not duplicate
  inline findings.
- Write one inline comment per unique issue. State the trigger or input, current
  behavior, expected behavior, and one concrete correction with enough code
  shape to implement. Give an exact condition, type, or module assignment. State
  precedence and compatibility behavior when relevant. Request a focused
  regression test that fails before the correction.
- Make each comment self-contained and as long as the evidence requires. It must
  answer what breaks, why, the replacement code shape, and the proof test. Keep
  one defect per comment.
- Cite prior art only when it clarifies intent. Prefer repository examples;
  otherwise use an external repository only when it owns the protocol or
  behavior being consumed. Link to a pinned commit and exact lines, then explain
  applicability. If repository behavior does not establish one fix, state the
  unresolved choice and viable alternatives.
- Do not restate the diff or leave abstract repair verbs without an exact
  operation.
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

No issues found. Checked premise, scope, API boundary, and diff minimality, then
bugs and repository instruction/contribution compliance.
```
