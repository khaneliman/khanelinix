# Skill Design Principles

Use when deciding what belongs in `SKILL.md` versus bundled resources.

## Context Budget

Assume model already knows general programming and writing. Include only
procedural knowledge, domain details, tool constraints, or reusable assets that
are not obvious from task request.

Prefer:

- concise examples over broad explanation
- explicit "read when" guidance for references
- scripts for deterministic repetitive work
- references for variant-specific detail

Avoid:

- generic best practices
- duplicated guidance across files
- long examples in root `SKILL.md`
- process notes about how skill was created

## Degrees Of Freedom

- High freedom: heuristics and text instructions for flexible tasks.
- Medium freedom: pseudocode and templates for preferred but adaptable patterns.
- Low freedom: scripts and exact commands for fragile or repeated operations.

Use stricter guidance only where failure risk justifies token cost.

## Progressive Disclosure

Layer skill content:

1. Metadata: name and description trigger skill.
2. `SKILL.md`: short playbook and routing.
3. References/scripts/assets: loaded or executed only for specific needs.

When skill supports multiple frameworks, modes, or output types, keep selection
logic in `SKILL.md` and put each mode's details in separate reference files.
