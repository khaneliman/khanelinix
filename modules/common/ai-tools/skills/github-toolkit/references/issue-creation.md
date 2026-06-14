# Issue Creation Play

Use when turning raw notes, logs, dictation, or screenshots into a GitHub issue.

## Workflow

1. Extract summary, environment, reproduction, expected behavior, actual
   behavior, errors, visual evidence, impact, and context.
2. Check templates first and enforce mandatory template usage.
3. Keep every section concise and action-oriented.
4. Save to `/issues/YYYY-MM-DD-short-description.md` unless user requests
   another destination.
5. Check `acceptance-criteria.md` before finalizing.

## Template Discovery (mandatory)

Repository templates are mandatory when present.

1. Look for issue templates:
   - `.github/ISSUE_TEMPLATE/` (directory)
   - `.github/ISSUE_TEMPLATE.md`
   - `.github/issue_template.md`
2. If any exist, do not use the base template below.
3. Load one template file and map its exact section/headings structure.
4. Preserve every required section and fill placeholders with concrete content.
5. Do not invent or remove mandatory sections.
6. If multiple templates exist and intent is ambiguous, ask the user to pick one
   before drafting.

## Template

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

### No template file available

Use this only when no repository issue template exists.

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
