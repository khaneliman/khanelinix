# Pull Request Creation Play

Use when drafting a PR body from branch changes, notes, review feedback, or
planned work summaries.

## Workflow

1. Detect mandatory PR template before drafting.
2. Apply one template verbatim; fill required fields with concise, repo-relevant
   detail.
3. Return PR title/body ready for `gh pr create`.
4. If template context is missing, request clarification.

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
