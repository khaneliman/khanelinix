---
name: skill-creator
description: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations.
license: Complete terms in LICENSE.txt
---

# Skill Creator

Create or update skills that add durable workflows, tool integrations, domain
knowledge, scripts, references, or assets without wasting context.

## Load Detail On Demand

- `references/design-principles.md`: token budget, degrees of freedom,
  progressive disclosure.
- `references/package-layout.md`: SKILL.md, scripts, references, assets.
- `references/creation-workflow.md`: step-by-step creation/update process.
- `references/workflows.md`: workflow-writing patterns.
- `references/output-patterns.md`: output contracts and examples.

Use bundled scripts directly when useful:

- `scripts/init_skill.py`
- `scripts/quick_validate.py`
- `scripts/package_skill.py`

## Design Rules

- Keep `SKILL.md` lean: trigger metadata plus essential workflow.
- Put detailed variants, schemas, long examples, and edge cases in
  `references/`.
- Put deterministic or repetitive work in `scripts/`.
- Put reusable output materials in `assets/`.
- Do not add README, changelog, install guide, or process notes unless user asks.
- Avoid duplicating same guidance in `SKILL.md` and references.

## Workflow

1. Clarify skill name, trigger use case, target agents, and expected outputs.
2. Decide package shape:
   - text-only workflow: `SKILL.md`
   - branching/deep guidance: `SKILL.md` + `references/`
   - fragile/repeated operation: add `scripts/`
   - reusable output material: add `assets/`
3. Write frontmatter `name` and `description` so trigger conditions are clear.
4. Write body as short decision tree plus required workflow.
5. Move non-core examples/details into references and link them with "read when"
   guidance.
6. Validate structure and metadata.

Read only focused references needed for current skill design problem.

## Validation

Run `scripts/quick_validate.py <skill-dir>` when available. Check:

- required `SKILL.md` exists
- frontmatter has `name` and `description`
- references/scripts/assets are linked from workflow when needed
- trigger text is specific enough to avoid accidental activation
- body fits progressive disclosure and avoids generic advice
