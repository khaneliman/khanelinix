---
name: how
description: "Explain a subsystem through direct codebase exploration. Use for how-it-works questions, walkthroughs, caller discovery, placement, or layering decisions. Use why for rationale and software-engineering for repository-wide evaluation."
---

# How

Explore the codebase to answer "how does X work?" questions. Produce
architectural explanations at the level of a senior engineer onboarding onto a
subsystem. Give the reader enough to build a working mental model, not annotated
source code.

Two modes:

1. **Explain** (default). Explore the codebase and produce a clear explanation.
2. **Critique**. Explain first, then spawn independent reviewers to identify
   architectural issues.

## Explain Mode

### 1. Understand the Question and Assess Complexity

Identify the scope: a subsystem, a feature flow, an architectural overview, or a
runtime trace. If the question is ambiguous, state your best-guess
interpretation before exploring. Do not ask. Let the user redirect you if the
guess is wrong.

Assess complexity to choose the approach:

- **Simple** (a single module, a small utility, a narrow question such as "how
  does function X work"): skip explorers. The explainer explores and explains in
  a single pass. Go to step 2b.
- **Complex** (a subsystem spanning multiple files or services, a cross-cutting
  feature, a full architectural overview): spawn parallel explorers first, then
  hand off to the explainer. Go to step 2a.

When in doubt, lean simple. You can still spawn explorers if the explainer hits
a wall.

### 2a. Explore (complex questions only)

Decompose the question into 2-4 parallel exploration angles, one distinct slice
of the subsystem per explorer, so explorers do not duplicate work. For "how does
the rate limiter work?": data model and state, request path and enforcement,
configuration and metrics. Narrow questions need 2 explorers; broad subsystems
up to 4.

Spawn all explorers in a single message as parallel read-only subagents. Give
each explorer the base prompt from
[explorer-prompt.md](references/explorer-prompt.md) plus a specific angle that
names its slice. The template owns the exploration method and the structured
findings format. Overlap between explorers is acceptable; the explainer
reconciles it.

Then go to step 3.

### 2b. Direct Explain (simple questions)

Spawn a single read-only subagent that explores and explains in one pass. The
subagent runs its own exploration with Glob, Grep, and Read, then writes the
explanation directly. Read [explainer-prompt.md](references/explainer-prompt.md)
for the communication style and output format. Use the same structure, without
explorer findings as input.

Then go to step 4.

### 3. Synthesize (complex questions only)

After all explorers return, spawn a single read-only subagent to synthesize
their findings into one coherent explanation. Give the explainer every
explorer's findings. Read [explainer-prompt.md](references/explainer-prompt.md)
for the full prompt template and output format. The explainer reconciles
overlapping findings, resolves contradictions, and weaves the slices into a
unified picture.

### 4. Present

Present the explainer's output to the user. Light edits for clarity and context
from the conversation are fine. Do not rewrite it substantially. The explainer's
communication is the product.

## Critique Mode

Use critique mode when the user asks for architectural issues, problems, or
improvements instead of understanding alone.

1. **Explain first.** Run the full explain flow above. You must understand the
   architecture before you critique it.
2. **Spawn critics** in a single message, one per distinct model family or
   subagent. Build each prompt from
   [critic-prompt.md](references/critic-prompt.md); every critic receives the
   explanation, the relevant file paths, and the rubric from
   [critique-rubric.md](references/critique-rubric.md).
3. **Lead judgment.** Apply the same framework as the `interrogate` skill: act
   as a pragmatic lead, not an aggregator. Categorize findings as act on,
   consider, noted, or dismissed.

Present the explanation first, then the critique verdict below it. The
explanation must stand on its own.
