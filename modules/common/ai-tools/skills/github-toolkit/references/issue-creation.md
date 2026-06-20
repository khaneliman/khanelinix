# Issue Creation Play

Use when turning raw notes, logs, dictation, or screenshots into a GitHub issue.

## Workflow

1. Extract summary, environment, reproduction, expected behavior, actual
   behavior, errors, visual evidence, impact, and context.
2. Discover and enforce repo template (see below).
3. Keep every section concise and action-oriented.
4. Save to `/issues/YYYY-MM-DD-short-description.md` unless user requests
   another destination.

## Template Discovery (mandatory)

1. Look for issue templates:
   - `.github/ISSUE_TEMPLATE/` (directory)
   - `.github/ISSUE_TEMPLATE.md`
   - `.github/issue_template.md`
2. If any exist, use one — do not fall back to the base template below.
3. Map exact section/heading structure; preserve every required section; fill
   placeholders with concrete content.
4. If multiple templates exist and intent is ambiguous, ask the user to pick one
   before drafting.

## Base Template (no repo template found)

```markdown
## Summary

## Environment

- **Product/Service**:
- **Region/Version**:
- **Browser/OS**: (if relevant)

## Reproduction Steps

1.

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

See [acceptance-criteria.md](acceptance-criteria.md) for severity definitions,
filename convention, and secrets-redaction rule.
