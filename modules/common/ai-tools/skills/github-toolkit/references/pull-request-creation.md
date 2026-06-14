# Pull Request Creation Play

Use when drafting a PR body from branch changes, notes, review feedback, or
planned work summaries.

## Workflow

1. Detect mandatory PR template path(s) before drafting.
2. Select one template and apply it verbatim.
3. Fill required fields with concise, repository-relevant detail.
4. Return PR title/body text ready for `gh pr create` body input.
5. Report if template context is missing and request user clarification.

## Template Discovery (mandatory)

Repository PR templates are mandatory when present.

1. Check for:
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `.github/pull_request_template.md`
   - `.github/PULL_REQUEST_TEMPLATE/` (directory)
2. If no path exists, report "no PR template detected" and proceed with a safe
   minimal PR body format.
3. If exactly one template exists, apply it.
4. If multiple templates exist, ask the user to choose one before drafting.
5. If a repo has branch protection or strict labels/sections, preserve any
   required sections exactly and only add content within template placeholders.

## Template

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

### No PR template file available

Use only when no repository template exists.

```markdown
## Summary

## Why

## What changed

## Testing
```
