---
name: architect
description: "Sketch types, signatures, and module structure before code, then implement against the agreed sketch. Use for /architect, 'architect this', 'design this', or non-trivial features where jumping to code locks in the wrong shape. Use software-engineering for repository-wide planning."
---

# Architect

Design before implementing. Sketch types, function signatures, class shapes, and
module boundaries with `not implemented` bodies and pseudocode. Synthesize
across multiple model perspectives, then fill in code against the chosen sketch.
If implementation proves the sketch wrong, discard the sketch and redesign.

## Start

Open a todolist with one entry per phase before starting. Autonomous runs
without checkpoints need the list to show phase position and to keep phases from
disappearing silently.

1. Ground
2. Sketch
3. Agree
4. Implement
5. Scrap

## Phase A: Ground the Problem

Build a real mental model of every system the new code touches. Run the `how`
skill over the relevant subsystems. Use critique mode when existing structure is
the constraint, or when the design must push back on that structure.

Naming a file is not grounding. Produce the traced model that `how` prescribes.
If the design redefines ownership or layering, also run the `why` skill on the
existing shape. The recorded rationale then becomes a constraint instead of a
guess.

Skip Phase A only when the work is greenfield with no surrounding system to
integrate.

## Phase B: Sketch

Run the `arena` skill with the design-sketch task and the Phase A grounding
artifacts. Pass [runner-prompt.md](references/runner-prompt.md) as each runner's
prompt. Arena owns runner selection; fan out across distinct model families or
subagents so candidates diverge. Each candidate produces a design package shaped
per [rationale-template.md](references/rationale-template.md): the caller's
usage written first, then the type sketch, function signatures, module map, and
prose rationale derived from that usage.

Design it twice. Require at least two structurally distinct candidates before
synthesis, even when the first looks sufficient. Compare whole shapes, not point
fixes inside one shape.

Screen every candidate against
[design-red-flags.md](references/design-red-flags.md) before synthesis. Reject
or revise shallow modules, information leakage, temporal decomposition, and
pass-through methods.

Compare viable candidates on interface depth. Prefer the design that hides more
complexity behind a smaller, simpler public surface. A rich interface keeps call
chains short by concentrating capability instead of scattering it across layers.

Arena returns one synthesized design package. The synthesis decision populates
the rationale's "Synthesis decision" section.

## Phase C: Agree (Opt-In)

Default: proceed directly to implementation with the synthesized design. Use no
human checkpoint.

Opt in to a checkpoint when the invoker asks explicitly: "/architect with
checkpoint", "stop and show me before implementing", or similar. Then surface
the synthesized design and pause for sign-off.

The synthesis can ship as its own commit either way. Scaffold first, so later
commits fill in bodies against a stable contract. Planned and scoped breakage
during fill-in is acceptable. For adversarial pressure on the design before
implementation starts, run the `interrogate` skill on the synthesized sketch.

If the human pushes back on the shape, in a checkpoint or after the fact, treat
that pushback as Phase A evidence. Re-ground and re-run Phase B before writing
more code.

## Phase D: Implement Against the Sketch

Replace `not implemented` bodies with code, and pseudocode with logic. The
synthesized sketch is the contract.

Deviations from the sketch are signal worth surfacing, not friction to absorb
silently. If a function needs a parameter the sketch did not anticipate, ask
whether the sketch was wrong, the requirement was missed, or the implementation
overreaches. Surface the deviation. Do not bolt it on.

## Phase E: Scrap When the Architecture Is Wrong

If implementation keeps producing friction the sketch cannot absorb, discard the
sketch. Do not bolt fixes onto a wrong design, per the fix-root-causes principle
in `engineering-principles`.

The signal is a pattern, not a single instance. Tells:

- The same shape of workaround appears repeatedly across unrelated code.
- Multiple unrelated edge cases each need a special-case branch.
- Types need escape hatches to compile, such as `any`, casts, or optional fields
  that are always set in practice.
- The "we need a lock" reflex appears when the sketch said the state was not
  shared.
- Callers must learn the abstraction's internal rules to use it.
- Two or more independent Phase D deviations share the same shape. Surfacing
  deviations is Phase D's job; a repeated pattern of them is Phase E's trigger.

Use judgment. A few edge cases do not condemn an architecture. Some problems are
legitimately complex; complexity in the data is not complexity in the design.
The rewrite trigger is repeated friction of the same shape, not a single hard
case.

When you scrap:

1. Re-run the `how` skill over what exists. Implementation lessons enter the new
   design as inputs, not impressions.
2. Redesign as if the new constraints had been day-one assumptions.
3. Subtract before adding, per the subtract-before-you-add principle in
   `engineering-principles`. The new sketch should be smaller than the old one
   before it grows.
4. Return to Phase B and re-run arena.

## Outputs

Write the caller's usage first and derive the type sketch from that usage.
Deliver one file with new types and signatures for small changes, or a module
map plus type definitions for larger work. Ship the rationale alongside the
sketch, shaped per [rationale-template.md](references/rationale-template.md),
including the usage sketch and the synthesis decision.
