---
name: github-toolkit
description: GitHub issue creation, PR review triage, and CI check-fix workflows using gh CLI.
---

# GitHub Toolkit

Use this skill for GitHub-specific workflows.

## How I choose what to do (progressive disclosure)

When invoked, choose one mode:

1. **issue-creation** — convert messy inputs into a structured GitHub issue
   markdown file.
2. **pr-review** — collect, prioritize, and address review comments on the PR for
   the current branch.
3. **ci-fix** — inspect failing PR checks and summarize actionable fix context.

If intent is unclear, ask for the mode before acting.

## 1) Issue Creation Mode

Use when the user provides raw notes, logs, dictation, or screenshots and wants a
ready-to-file GitHub issue.

- Follow the issue template below.
- Keep every section concise and action-oriented.
- Save output to `/issues/` as `YYYY-MM-DD-short-description.md` unless the
  user requests another destination.
- Match acceptance criteria in [acceptance-criteria.md](references/acceptance-criteria.md).

### Issue Template

```markdown
## Summary

## Environment

- **Product/Service**:
- **Region/Version**:
- **Browser/OS**: (if relevant)

## Reproduction Steps

1. [Step]

## Expected Behavior

## Actual Behavior

## Error Details

`[error text / logs if present]`

## Visual Evidence
[attachment references]

## Impact
[Critical/High/Medium/Low + short rationale]

## Additional Context
```

## 2) PR Review Mode

Use for review-comment triage on the PR associated with the current branch.

### Workflow

1. Verify GitHub CLI auth:
   - `gh auth status`
2. Run:
   - `python "<path-to-skill>/scripts/fetch_comments.py"`
3. Summarize actionable review threads and comments.
4. Ask the user which items to address.
5. Implement only selected items, then report what changed.

If auth/rate limiting fails, ask the user to rerun `gh auth login` and retry.

## 3) CI Fix Mode

Use for failing checks in the PR linked to the current branch (or provided PR).

### Workflow

1. Verify GitHub CLI auth:
   - `gh auth status`
2. Resolve PR:
   - current branch PR via `gh pr view --json number,url` or user-provided PR
     number/URL.
3. Summarize failures:
   - `python "<path-to-skill>/scripts/inspect_pr_checks.py" --repo "." --pr "<num-or-url>"`
   - Add `--json` when machine-friendly output is needed.
4. For each failure, provide:
   - check name
   - details URL/run link
   - short failure context
5. Do not attempt non-GitHub-actions providers; return URL only and stop.
6. Ask explicit approval before implementing fixes.

If `gh pr checks` field shape changes, rerun with reported accepted fields.

## Cross-Mode Notes

- Prefer minimal, safe edits first.
- Ask for explicit approval before touching files from issue summaries or CI
  recommendations.
- For destructive git operations (hard reset, force push, branch deletion), call out
  risk before running them.
