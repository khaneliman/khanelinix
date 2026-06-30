# PR Review Play

Use for review-comment triage or high-signal review of current branch PR.

## Workflow

1. Verify auth: `gh auth status`.
2. Fetch comments: `python "<path-to-skill>/scripts/fetch_comments.py"`.
3. Read root and changed-path guidance: `AGENTS.md`, `CONTRIBUTING.md`,
   `CLAUDE.md`, local instruction files.
4. Compare diff, commits, and PR metadata against guidance.
5. Summarize actionable review threads or validated findings.
6. Ask user which items to address before editing.
7. Implement only selected items and report changes.

If auth/rate limiting fails, ask user to run `gh auth login`.

## High-Signal Review Policy

Flag only highly likely defects:

- syntax, type, compile, or unresolved-reference failures
- logic that definitely produces wrong behavior
- clear security or data-loss defects in changed code
- clear instruction-file violations scoped to changed file
- clear contribution-policy violations: commit message, atomicity, required
  tests/checks, licensing, secrets

Do not flag style, subjective quality, pre-existing problems, speculative edge
cases, duplicates, or normal linter findings unless repo instructions require.
Validate each issue against diff and relevant local instructions before posting.

## Don't Re-Run CI Work

CI already runs the mechanical checks, and the PR already shows their results.
Re-running them during review proves nothing new, adds noise, and lengthens the
review.

- Do not re-run tests, builds, linters, or formatters just to confirm what a
  green check already reports. Read the check results instead.
- Do not restate passing checks or paste their output as findings.
- Do judge whether a check actually exercises the change: does the suite cover
  the new code path, or pass without touching it? Is there changed behavior with
  no check behind it? A check that stays green regardless of the diff proves
  nothing — that gap is the finding worth flagging.
- Spend review effort on what CI cannot: logic correctness, design, policy
  compliance, and missing coverage.

## Review Writing

- Make the review body short: outcome, confidence, and any global context only.
- Do not restate inline findings in the review body.
- Write inline comments like teammate guidance: problem, reason, next step.
- Keep each inline discussion to 1-3 short sentences unless evidence needs more.
- Let suggestion blocks stand on their own; do not narrate the patch twice.
- Avoid canned review phrases like "overall", "it appears", and "great work".

## Inline Comments

- Prefer one review containing all inline comments over sequential standalone
  comments.
- Post one comment per unique issue.
- Use Conventional Comments labels for scanability, but keep prose natural.
- Include suggestion blocks only when they fully fix issue.
- Cite local instruction/contribution files for compliance findings.
- Use full GitHub URLs with concrete commit SHA for code links.

## Posting Pending Reviews (API Mechanics)

When creating a draft/pending review with inline comments programmatically:

- REST `POST /repos/{owner}/{repo}/pulls/{n}/reviews` silently drops
  `start_line`/`start_side` on its `comments[]` items, storing every comment as
  single-line. Multi-line `suggestion` blocks then anchor to the end line only —
  "Commit suggestion" replaces one line and produces broken code.
- For any review containing a multi-line suggestion, use GraphQL instead:
  1. `addPullRequestReview(input: {pullRequestId, body})` with no `event` to
     create the pending review.
  2. `addPullRequestReviewThread(input: {pullRequestReviewId, path, startLine,
     startSide, line, side, body})`
     per comment.
- Verify ranges via GraphQL
  (`node(id:) { ... on PullRequestReview {
  comments { path startLine line } } }`).
  REST returns `line: null` on pending-review comments even when ranges are
  stored correctly, so REST output cannot distinguish a broken anchor from a
  pending one.
- A suggestion block replaces exactly the anchored range `startLine..line`; the
  suggestion body must be a drop-in replacement for those lines, including
  indentation.

## Conventional Comments

Format:

```markdown
<label> [decorations]: <subject>

[discussion]
```

Use labels to make intent clear:

- `issue`: defect or policy violation that must be fixed.
- `suggestion`: improvement worth considering, usually non-blocking.
- `question`: clarification request needed to judge correctness.
- `nitpick`: tiny preference or cleanup; always non-blocking.
- `note`: useful context; non-blocking.
- `praise`: positive feedback; do not mix with required changes.
- `todo`: small required follow-up.

Use decorations when status or scope matters:

- `(blocking)`: must be resolved before approval or merge.
- `(non-blocking)`: optional or deferrable.
- `(if-minor)`: worth doing only if change is small.
- Add scoped tags sparingly, for example `(security, blocking)` or
  `(tests, non-blocking)`.

Rules:

- Start every inline finding with `<label> [decorations]: <subject>`.
- Use `(blocking)` only for high-signal review findings from policy above.
- Keep subject one line and imperative or descriptive.
- Put only necessary evidence, reasoning, and next step in discussion body.
- Avoid labels that weaken priority; choose one primary label per comment.

Examples:

```markdown
issue (blocking): validate `owner` before using it in shell command

`owner` comes from PR metadata and reaches command construction. Pass it as an
argument array element or validate it before use.
```

```markdown
suggestion (non-blocking): move duplicate retry logic into helper

Both paths now retry with identical backoff. Shared helper would reduce drift,
but current behavior is correct.
```

No-issues comment when requested:

```markdown
## Code review

No issues found. Checked for bugs and repository instruction/contribution
compliance.
```
