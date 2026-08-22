# Durable Agent Brief

Use this format when an issue or pull request must remain actionable for a
future agent after code moves or discussion context decays. Treat the brief as
the handoff contract. Keep issue history as supporting context.

## Writing Rules

- Describe current and desired behavior. Do not prescribe implementation steps.
- Name stable interfaces, types, signatures, configuration shapes, and external
  contracts when they constrain the result.
- Avoid file paths and line numbers unless the path itself is a public contract.
- Give independently verifiable acceptance criteria.
- State explicit exclusions that prevent adjacent work or gold-plating.
- Separate confirmed facts from assumptions and unresolved questions.

## Template

```markdown
## Agent Brief

**Category:** bug / enhancement / maintenance

**Summary:** one-line required outcome

**Current behavior:**

Observable status quo or failure. Include confirmed reproduction evidence for a
bug. For a pull request, describe the current diff and its remaining gaps.

**Desired behavior:**

Observable result, edge cases, and error behavior after completion.

**Key contracts:**

- Stable interface or type: required behavior and constraint
- Configuration or external API shape: compatibility requirement

**Acceptance criteria:**

- [ ] One independently verifiable outcome
- [ ] One regression or compatibility outcome

**Out of scope:**

- Adjacent behavior that must remain unchanged

**Open questions:**

- Unresolved fact that blocks or may change implementation
```

Omit `Open questions` when none remain. A brief is not ready for autonomous
handoff while a material product choice or missing authority remains unresolved.

## Attribution

Adapted from Matt Pocock's triage agent-brief guidance. Prose is original.
Upstream terms are in
[LICENSE-matt-pocock.txt](../LICENSES/LICENSE-matt-pocock.txt).
