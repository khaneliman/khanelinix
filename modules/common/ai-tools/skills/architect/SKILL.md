---
name: architect
description: "Sketch interfaces, state, and module structure before code. Use for explicit design-led implementation or as a caller-owned design method when material uncertainty makes the change shape non-obvious."
---

# Architect

Choose the smallest design artifact that resolves a material uncertainty.
Ground it in actual callers and constraints before implementing.

## Invocation Boundary

- **Caller-owned method:** when another lifecycle invokes this skill during
  Shape, return the design, acceptance evidence, and open choices. Do not begin
  implementation or take over the caller's lifecycle.
- **Direct design-led implementation:** when the user requests design and
  implementation, own that sequence through verification and handoff. Preserve
  explicit plan-only or checkpoint requests. Use the existing lifecycle's
  verification and review methods rather than inventing another gate policy.

Reuse completed grounding, requirements, and checks. Do not rerun a phase merely
because its evidence came from another skill or worker.

## Ground

Trace the affected callers, state, interfaces, and constraints. Use `how` when
structure is unfamiliar and `why` when recorded ownership or historical intent
could change the design. A caller's current traced evidence can satisfy this
phase. Greenfield work still needs requirements and integration constraints.

Separate verified requirements from assumptions. Ask only for a material
product choice that cannot be resolved from available evidence.

## Sketch

Write the caller's usage first, then derive the interface or state model.
Select an artifact for the unresolved question:

- Types, signatures, and pseudocode for algorithms or API contracts.
- A module or state diagram for ownership, transitions, and failure behavior.
- A runnable throwaway mockup for interaction or state/logic choices.
- Images or visual variants when appearance itself is the decision.

Use existing domain or visual tools when needed. Mark throwaway artifacts and
record the question they answered; do not add production infrastructure or
unnecessary tests to a disposable exploration.

Start with one sketch. Use `arena` for explicitly requested competing designs,
one-way-door decisions, or consequential uncertainty between viable shapes.
Then require at least two structurally distinct candidates, an independent judge,
and a synthesized decision. Use `multi-provider-sdlc` when distinct model-family
perspectives are needed; subscription diversity alone is not enough.

For competing candidates, pass [runner-prompt.md](references/runner-prompt.md)
and use [rationale-template.md](references/rationale-template.md). For one sketch,
record only the problem, caller usage, shape, material tradeoffs, acceptance
checks, and unresolved choices. Do not manufacture alternatives or synthesis.
Consult [design-red-flags.md](references/design-red-flags.md) when boundaries or
interface complexity remain uncertain.

## Return or Implement

Return the sketch to a lifecycle caller. For direct design-led implementation,
proceed when scope and authority are settled. Pause only for a requested
checkpoint or unresolved blocking choice. Adversarial pressure on a consequential
design can use `interrogate`; routine designs do not require a council.

Implement against the chosen contract, preserving opt-in TDD. Use the
`verified-slice` method in `engineering-principles` for proportional verification,
review, correction, and atomic commits under current or standing authority.
A scaffold is independently committable only when it remains green and useful.

## Revise When Evidence Changes

Surface material deviations from the sketch. If implementation reveals a missed
constraint, update the design and affected acceptance evidence before continuing.
Do not restart all research for one edge case.

When friction forms a pattern, consult [scrap-signals.md](references/scrap-signals.md).
Re-ground only the invalidated assumptions, simplify the design, and return to
Sketch. Repeat candidate fan-out only when the uncertainty still warrants it.
