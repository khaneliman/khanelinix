# Issue Acceptance Criteria

## Issue Template (fallback when no repo template)

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

`[error text / logs]`

## Visual Evidence

[attachment references]

## Impact

[Critical/High/Medium/Low + short rationale]

## Additional Context
```

## Severity

| Severity | Definition                              |
| -------- | --------------------------------------- |
| Critical | Service down, data loss, security issue |
| High     | Major feature broken, no workaround     |
| Medium   | Feature impaired, workaround exists     |
| Low      | Minor inconvenience, cosmetic           |

## Rules

- **File name**: `YYYY-MM-DD-short-description.md`
- **Secrets**: replace with `[PLACEHOLDER]` — never expose real keys, IDs,
  emails, or tokens
- **Errors**: always in fenced code blocks
