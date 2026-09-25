# Pull Request Review Authoring

Use for high-signal review and explicit inspection or mutation of GitHub reviews
owned by current actor. Use [pr-feedback.md](pr-feedback.md) for existing review
comments.

The `premise-review` method in `engineering-principles` is the review contract:
its packet, premise gate, evidence axes, finding format, and verdict apply here.
This mode adds GitHub history, duplicate handling, contributor conversation,
review operations, and the public comment format.

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
4. Load the available specialist skill for each changed language or domain, such
   as `rust-toolkit`, `typescript-best-practices`, or `nix-toolkit`. A missing
   skill does not block review of code you can assess directly. State a material
   coverage gap, and return a blocked review only when missing evidence or
   capability prevents a reliable verdict.
5. Run the premise gate from the `premise-review` method in
   `engineering-principles` before reading the diff for defects. Record each
   premise concern as a conventional comment with evidence from the issue, the
   PR body, and the repository. When the gate fails, draft a review that
   recommends redesign or closure with the native abstraction or existing
   capability named, even when every check is green.
6. Review only diff plus necessary local context.
7. Revalidate each finding against the current PR head, changed code, and
   repository policy before drafting or revising it.
8. Return draft findings by default. Inspect, create, update, or delete a review
   only when user explicitly requests it.

Never submit pending review, approve, request changes, push, or edit the
reviewed checkout. Apply proposed fixes only in isolated validation scratch.
Leave final publication to user in GitHub UI.

## Full-history and duplicate gate

Before reviewing, read the full paginated PR description, issue discussion,
reviews and inline threads across all head SHAs. Include all participants,
author replies, and resolved/outdated state. Verify pagination completeness;
block the review when history is incomplete.

A changed head permits reconsideration, not repetition. Compare every proposed
finding against prior feedback by root cause, consequence and requested fix, not
just text, comment IDs or review commit SHA. Do not repost unresolved findings
in fresh threads. Incorporate author rebuttals and verify disputed upstream
behavior against the relevant packaged source. Previous generated configuration
is not proof of supported or working runtime behavior.

Recheck history before writing. Follow up to answer a question, provide
requested help, acknowledge a correction, or add materially new evidence. Public
replies still require user authorization. Keep fixed, outstanding, rebutted and
genuinely new issues separate in private review notes.

## Contributor Conversation

- Read the contributor's latest reply before drafting more findings. Answer each
  direct question or request for help first; do not treat it as another review
  trigger. Ask a short clarifying question only when a needed fact is missing.
- Explain the disputed behavior plainly and offer the smallest validated code
  example or fix. Own unclear wording or a mistaken finding, acknowledge the
  correction, and withdraw concerns that no longer hold.
- Reply in the existing thread using its context, not the initial-finding
  template. A clarification need not repeat the code block or test evidence
  already visible; include new code when that is what the contributor needs.
- Batch actionable findings in one pass. Do not drip-feed nits, turn optional
  preferences into blockers, or raise fresh polish while the author addresses
  the original request. Recheck changed behavior, not the whole PR by default;
  raise newly demonstrated defects when they materially affect correctness.
- If the contributor requests help implementing a fix, prepare the concrete
  patch within authorized scope rather than restating the request. Do not post
  encouragement or pressure in place of an answer. Stop when concerns are
  resolved; silence is preferable to another low-value comment.

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
again immediately before mutation. Updates and comment deletions refuse a review
that is no longer pending unless the input sets `"allow_submitted": true`. Set
it only when the user asked in the current turn to change published content,
after re-inspecting that review; a user can submit between turns. When revising
a pending review, select only the exact review owned by the current actor. Never
submit it. GitHub permits review-summary updates after submission but permits
whole-review deletion only while a review is pending.

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

Apply the test-value and execution boundary from `premise-review`, including in
delegated packets. Assess whether assertions and fixtures detect realistic
defects and cover the changed behavior, not whether checks currently pass.
Missing coverage can be a finding when repository policy or risk requires it.

## Review Writing

- Keep the public review body to a short outcome. Do not repeat inline findings
  or publish cleared premise concerns, confidence scores, and investigation
  logs.
- Write one inline comment per actionable issue. Default to one or two short
  sentences explaining the trigger and consequence, followed by the exact fix
  and one line of validation evidence. Add detail only when needed to apply the
  fix safely. Keep the full reasoning in internal review notes.
- Use direct, collegial language: name what breaks and show what works. Avoid
  rhetorical questions, abstract repair requests, and unsolicited tutorials.
- Understand callers, relevant contracts, and edge behavior before recommending
  replacement code. Validate that exact replacement with a focused check in an
  isolated scratch copy or worktree; leave the reviewed checkout unchanged. Use
  repository-ignored build scratch or the user cache, not installed skills. This
  tests the proposed fix, not the unchanged PR's CI status.
- For a bug fix, reproduce the relevant failure and check the replacement on
  that case. Reuse an existing check when adequate; do not automatically ask the
  author to add a new regression test. State the command or probe and observed
  result briefly. Static inspection alone is not a claim that code was tested.
- If validation is unavailable, do not publish an optional code suggestion. A
  confirmed defect may still warrant a short finding: give the evidence and
  state that a fix has not been validated. Ask only for a concrete missing fact.
- Cite local instructions for compliance findings. Link prior art only when it
  is needed to understand the correction, using a pinned commit and exact lines.

### Suggestion blocks

- Select the smallest contiguous diff range that the replacement can fully fix.
  "Fully fix the selected range" does not authorize replacing a surrounding
  option, function, or expression block for a one-line or one-word change.
- Do not duplicate unchanged context in a suggestion block. The replacement must
  contain only the selected lines' new content, not surrounding lines that
  remain unchanged.
- Before writing the comment, compare the selected lines with the proposed
  replacement. Confirm that every selected line is intentionally replaced and
  that no unchanged context was added; if this comparison fails, narrow the
  range or rewrite the replacement.
- For coordinated edits that cannot be expressed in the same minimal range,
  provide a small fenced diff with file paths, or separate applicable suggestion
  blocks. Validate the combined change. Do not expand a suggestion block with
  unrelated lines or leave required companion edits as prose-only homework.
- Cite local instructions for compliance findings and concrete commit SHAs for
  code links.

Format inline comments as:

````markdown
issue: <trigger and consequence>. <why this replacement fixes it, if needed>

```suggestion
<exact replacement for the selected lines>
```

Checked: `<focused command or probe>`; <observed result>.
````

This is a code-fix template, not a requirement to invent code for policy
findings, missing facts, or a confirmed defect without a validated fix.

Use `issue`, `suggestion`, `question`, `nitpick`, `note`, `praise`, or `todo`.
Use `(blocking)` only for high-signal defects; otherwise use `(non-blocking)` or
omit decoration. Keep one primary label.

A no-issues verdict still requires checking premise, scope, API boundary, and
diff minimality internally. Do not publish that checklist.

No-issues comment when requested:

```markdown
No issues found.
```
