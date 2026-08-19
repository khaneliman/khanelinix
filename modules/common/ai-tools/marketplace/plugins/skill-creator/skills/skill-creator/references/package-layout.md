# Skill Package Layout

Use when deciding files to create.

## Required

```text
skill-name/
└── SKILL.md
```

`SKILL.md` needs YAML frontmatter:

```yaml
---
name: skill-name
description: Clear trigger conditions and supported task shape.
---
```

Body should contain mode selection, core workflow, and links to focused
resources.

## Optional Resources

`scripts/`: deterministic or repetitive operations. Prefer executable scripts
over retyping long code.

`references/`: detailed mode-specific guidance, schemas, examples, API notes,
or troubleshooting. Each file should have clear read conditions from `SKILL.md`.

`assets/`: reusable output resources such as templates, images, fonts, fixtures,
or starter files. Assets are used, not loaded into context by default.

## Do Not Add By Default

- `README.md`
- install guide
- changelog
- process notes
- duplicate quick references

Extra docs add clutter unless user explicitly requests them.
