# Issue Creation Play

Use when turning raw notes, logs, dictation, or screenshots into a GitHub issue.

## Workflow

1. Resolve target repository and source notes, logs, or screenshots. Redact
   secrets.
2. Extract summary, environment, reproduction, expected and actual behavior,
   errors, visual evidence, impact, and context.
3. Discover and enforce repository template. Read `CONTRIBUTING.md`, root/local
   instructions, and directly relevant docs before drafting.
4. Check likely duplicates and linked pull requests.
5. Fill selected template exactly with concise, evidence-backed prose.

## Authority and Output

Creating issue requires explicit user request. Without it, save draft to
`issues/YYYY-MM-DD-short-description.md` unless user names another destination.
When creation is explicit, create issue from filled template. Do not label,
assign, close, or modify unrelated files unless separately requested.

If template choice or required contribution context is ambiguous, stop with
concise blocker and do not create issue.

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
