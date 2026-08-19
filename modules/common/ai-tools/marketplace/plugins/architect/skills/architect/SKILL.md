---
name: architect
description: "Sketch types, signatures, and module structure before code, then implement against the agreed sketch. Use for /architect, 'architect this', 'design this', or non-trivial features where jumping to code locks in the wrong shape. Use software-engineering for repository-wide planning."
---

# Architect

Design before implementing. Sketch types, signatures, and module boundaries with
`not implemented` bodies and pseudocode, synthesize across multiple model
perspectives, then fill in code against the chosen sketch. If implementation
proves the sketch wrong, discard the sketch and redesign.

Open a todolist with one entry per phase (Ground, Sketch, Agree, Implement,
Scrap) before starting. Autonomous runs without checkpoints need the list to
show phase position and to keep phases from disappearing silently.

## Phase A: Ground the Problem

Build a real mental model of every system the new code touches. Run the `how`
skill over the relevant subsystems. Use critique mode when existing structure is
the constraint, or when the design must push back on that structure.

Naming a file is not grounding; produce the traced model that `how` prescribes.
If the design redefines ownership or layering, also run the `why` skill so the
recorded rationale becomes a constraint instead of a guess.

Skip Phase A only for greenfield work with no surrounding system to integrate.

## Phase B: Sketch

Run the `arena` skill with the design-sketch task and the Phase A grounding
artifacts. Pass [runner-prompt.md](references/runner-prompt.md) as each runner's
prompt. Arena owns runner selection; fan out across distinct model families or
subagents so candidates diverge. Each candidate produces a design package shaped
per [rationale-template.md](references/rationale-template.md), the caller's
usage written first.

Design it twice: require at least two structurally distinct candidates before
synthesis, even when the first looks sufficient. Compare whole shapes, not point
fixes inside one shape.

Screen every candidate against
[design-red-flags.md](references/design-red-flags.md) before synthesis. Reject
or revise flagged shapes, and compare viable candidates on interface depth as
that reference defines it.

Arena returns one synthesized design package. The synthesis decision populates
the rationale's "Synthesis decision" section.

## Phase C: Agree (Opt-In)

Default: proceed directly to implementation with no human checkpoint. Opt in
only when the invoker asks explicitly ("/architect with checkpoint", "stop and
show me before implementing"); then surface the synthesized design and pause for
sign-off. For adversarial pressure on the design before implementation, run the
`interrogate` skill on the synthesized sketch.

The synthesis can ship as its own commit either way. Scaffold first, so later
commits fill in bodies against a stable contract. Planned and scoped breakage
during fill-in is acceptable.

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
sketch instead of bolting on fixes, per the fix-root-causes principle in
`engineering-principles`.

The signal is a pattern, not a single instance. Judge against the tells in
[scrap-signals.md](references/scrap-signals.md) before condemning a sketch. A
few edge cases do not condemn an architecture.

When you scrap:

1. Re-run the `how` skill over what exists. Implementation lessons enter the new
   design as inputs, not impressions.
2. Redesign as if the new constraints had been day-one assumptions. Per the
   subtract-before-you-add principle, the new sketch should be smaller than the
   old one before it grows.
3. Return to Phase B and re-run arena.

## Outputs

Write the caller's usage first and derive the type sketch from that usage.
Deliver one file with new types and signatures for small changes, or a module
map plus type definitions for larger work. Ship the rationale alongside the
sketch, shaped per [rationale-template.md](references/rationale-template.md).
