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

## Inline Comments

- Prefer one review containing all inline comments over sequential standalone
  comments.
- Post one comment per unique issue.
- Write review comments in Conventional Comments style.
- Include suggestion blocks only when they fully fix issue.
- Cite local instruction/contribution files for compliance findings.
- Use full GitHub URLs with concrete commit SHA for code links.

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
- Put evidence, reasoning, and next step in discussion body.
- Avoid labels that weaken priority; choose one primary label per comment.

Examples:

```markdown
issue (blocking): validate `owner` before using it in shell command

This value comes from PR metadata and reaches `gh` through command construction.
Use argument arrays or explicit validation before execution.
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
