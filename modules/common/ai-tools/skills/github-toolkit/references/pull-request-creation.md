# Pull Request Creation Play

Use when drafting a PR body from branch changes, notes, review feedback, or
planned work summaries.

## Workflow

1. Resolve repository, current/base branches, remote, diff, related issues, and
   worktree state. For an existing PR, collect commits, files, and checks with
   `scripts/pr_snapshot.py` instead of rebuilding API queries.
2. Detect mandatory PR template. Read `CONTRIBUTING.md`, root and changed-path
   instructions, and directly relevant docs.
3. Apply one template verbatim and fill required fields with concise,
   repository-relevant detail.
4. Note contribution gaps: missing tests/docs/issue links, atomic-history
   concerns, licensing/secrets risk, dirty tree, or unpushed commits.
5. Return title/body ready for `gh pr create`.

## Authority and Output

Creating pull request requires explicit user request. Draft title/body by
default. If creation is explicit but branch is dirty, unpushed, or missing
required context, return title/body plus exact blocker. Do not push, force-push,
rebase, amend, or edit files unless separately requested. Create draft PR only
when user asks for draft state.

## Template Discovery (mandatory)

1. Check for:
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `.github/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE/` (directory)
2. If none found, report "no PR template detected" and use the base template
   below.
3. If exactly one template exists, apply it.
4. If multiple templates exist, ask the user to choose before drafting.
5. Preserve required sections and branch-protection labels exactly; only add
   content within template placeholders.

## Base Template (no repo template found)

```markdown
## Summary

[One-line summary]

## Why

[Reason for the change]

## What changed

- [Change item]

## Testing

- [Tests run and results]

## Related Issue(s)

- [Issue links]
```
