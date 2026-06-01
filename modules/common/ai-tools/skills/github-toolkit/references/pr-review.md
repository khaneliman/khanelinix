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
- Include suggestion blocks only when they fully fix issue.
- Cite local instruction/contribution files for compliance findings.
- Use full GitHub URLs with concrete commit SHA for code links.

No-issues comment when requested:

```markdown
## Code review

No issues found. Checked for bugs and repository instruction/contribution
compliance.
```
