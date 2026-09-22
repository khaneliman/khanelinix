---
name: skill-creator
description: Create or update portable agent skills and their supporting resources.
license: Complete terms in LICENSE.txt
metadata:
  disable-model-selection: "true"
---

# Skill Creator

Create skills that supply non-obvious guidance for a defined task. Preserve the
user's scope, existing authorization, invocation metadata, and licenses.
Assume the agent can handle ordinary programming and tool use.

## Design

- Describe the capability and its actual trigger briefly. Avoid lists of every
  supported feature or broad keywords that attract unrelated tasks.
- Keep the root self-contained for simple work. For substantial modes, link
  supporting references with a clear read condition. Do not load all modes.
- Describe outcomes and decision criteria for flexible work. Reserve fixed
  sequences for fragile operations or concrete correctness constraints.
- Add scripts when repeated mechanics justify them, references for conditional
  detail, and assets for reusable output. Inspect callers before removing
  existing resources. Do not add empty scaffolding or duplicate documentation.
- Keep existing invocation policies. For new skills, allow automatic discovery
  unless the user requests explicit-only invocation. Sensitivity alone is not
  a discovery gate; check authorization before the consequential action.

## Create or Update

Use the request and existing package to establish the trigger, output, and
constraints. Ask only when missing information materially affects the result.
A narrow update may need only an edit and focused validation, not initialization
or package planning. Do not turn a past example into a universal requirement.

For new packages, use `scripts/init_skill.py` when it helps. Preserve a requested
location and create only resources with a current use. Use
`scripts/package_skill.py` only when an archive is part of the requested output.

## References

- Read [design-principles.md](references/design-principles.md) for context
  placement and degree-of-freedom decisions.
- Read [package-layout.md](references/package-layout.md) when choosing package
  files and resource types.
- Read [creation-workflow.md](references/creation-workflow.md) for a new or
  substantially revised package, adapting its steps to the task.
- Read [workflows.md](references/workflows.md) or
  [output-patterns.md](references/output-patterns.md) when a workflow or output
  contract needs examples.

## Validation

Run `scripts/quick_validate.py <skill-dir>`. Check reference reachability,
metadata preservation, and trigger precision. Run new or changed scripts against
representative inputs. Structural validation does not prove useful behavior.

For a complex or risky skill, use an independent agent with a realistic request
and raw artifacts when delegation is available. Do not supply the intended
answer. Keep evaluation side effects within the authorized scope, inspect the
result, and revise only where observed behavior warrants it.
