# Skill Creation Workflow

Use for new skill creation or substantial updates.

## 1. Understand Task

Collect concrete examples:

- user requests that should trigger skill
- user requests that should not trigger skill
- required tools or scripts
- expected outputs
- failure modes that need guardrails

## 2. Plan Package

Choose smallest structure that works:

- simple workflow: root `SKILL.md`
- multi-mode workflow: root router plus `references/<mode>.md`
- fragile/repeated operation: add `scripts/`
- reusable output material: add `assets/`

## 3. Create Files

Use `scripts/init_skill.py` when available. Otherwise create `SKILL.md` with
frontmatter and concise body.

## 4. Write Root Playbook

Include:

- when to use skill
- mode or task routing
- core workflow
- "read when" links to references
- validation or output contract

Do not paste every variant into root file.

## 5. Add Focused References

One reference should answer one specific need: framework, mode, output type,
schema, troubleshooting area, or examples. If reference becomes broad, split it.

## 6. Validate And Package

Run:

```bash
python scripts/quick_validate.py <skill-dir>
python scripts/package_skill.py <skill-dir>
```

If scripts are absent, manually check frontmatter, file links, and trigger
specificity.
