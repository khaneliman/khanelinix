---
name: arena
description: "Spawn N parallel candidates at the same task, pick a base, graft the strongest parts of the losers into it. Use for /arena, 'arena this', 'throw it in the arena', or when one attempt at a non-trivial artifact would lock in the wrong shape."
---

# Arena

Fan out N parallel attempts at the same task. Read every candidate end to end.
Pick the strongest as base, graft the best ideas from others, and verify the
synthesized result.

## Workflow

### 1. Frame

Define the task prompt and rubric before spawning:

1. State the exact artifact to produce.
2. Derive 3-6 concrete gradeable rubric criteria.
3. Select distinct model families or subagents for the runner pool.
4. Assign isolated output directories or worktrees per candidate.

### 2. Fan Out

Spawn all N candidate subagents concurrently with the task prompt, shared
context, and instructions to return both the artifact and a brief design
rationale.

### 3. Cross-Judge

Spawn an independent judge subagent on a distinct model family to score all
candidates against the rubric and recommend a base candidate with rationale.

### 4. Pick Base

Score each candidate against the rubric criteria. Compare picks with the
cross-judge:

- Pick the candidate that maintainers can extend most easily while preserving
  invariants.
- Favor cleaner boundaries and minimal surface area.
- Record the base selection rationale.

### 5. Graft

Review losing candidates for isolated high-value ideas or edge-case handling:

- Fold improvements into the base cleanly rather than copy-pasting.
- Preserve a single coherent design model.
- Document grafted ideas and rejected alternatives.

### 6. Verify

Verify the synthesized result against real tests, compilers, or live runtimes.

## Output

Deliver the synthesized artifact accompanied by a brief synthesis note detailing
the base selection, grafted components, rejected approaches, and verification
results.
