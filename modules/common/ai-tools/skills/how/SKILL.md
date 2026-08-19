---
name: how
description: "Explain how a subsystem works from direct codebase exploration, and optionally critique its architecture. Use for \"how does X work\", code walkthroughs before changing something, and placement / ownership / layering questions (\"where should this live\", \"which package owns this\", \"is this the right layer\"). Covers subsystem architecture, runtime flow, and onboarding mental models. Use why for motivation. Use software-engineering for repository-wide architecture evaluation."
---

# How

Explore the codebase to answer "how does X work?" questions. Produce
architectural explanations at the level of a senior engineer onboarding onto a
subsystem. Give the reader enough to build a working mental model, not annotated
source code.

Companion to `why` (motivation and history) and `blast-radius` (downstream
impact of a change).

Two modes:

1. **Explain** (default). Explore the codebase and produce a clear explanation.
2. **Critique**. Explain first, then spawn independent reviewers to identify
   architectural issues.

## Explain Mode

### 1. Understand the Question and Assess Complexity

Parse what the user asks about:

- "How does the rate limiter work?", a subsystem.
- "How do we handle billing for on-demand usage?", a feature flow.
- "How is the auth service structured?", an architectural overview.
- "Walk me through what happens when a user submits a form", a runtime trace.

Identify the scope. If the question is ambiguous, state your best-guess
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

Decompose the question into 2-4 parallel exploration angles. Give each explorer
a distinct slice of the subsystem so explorers do not duplicate work. Example
split for "how does the rate limiter work?":

- Explorer 1: data model and state management.
- Explorer 2: request path and enforcement.
- Explorer 3: configuration and metrics infrastructure.

The right decomposition depends on the question. Use your judgment. For narrow
questions, 2 explorers is enough. For broad subsystems, use up to 4.

Spawn all explorers in a single message as parallel read-only subagents. Give
each explorer the base prompt from
[explorer-prompt.md](references/explorer-prompt.md) plus a specific exploration
angle that names its slice. Each explorer should:

- Start broad. Glob for relevant directories. Grep for key types, interfaces,
  and class names.
- Follow the thread. From an entry point, trace the call chain: callers,
  callees, data flow, and type definitions.
- Read the actual code. Do not guess from file names.
- Stop when it can describe the full path from input to output, or from trigger
  to effect, without hand-waving any step.
- Note anything surprising, non-obvious, or easy for a newcomer to get wrong.

Each explorer returns structured findings: components found, flow traced, files
read, and anything non-obvious. Overlap between explorers is acceptable. The
explainer reconciles it.

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
explorer's findings. The explainer writes the human-facing explanation in the
output format below. Read [explainer-prompt.md](references/explainer-prompt.md)
for the full prompt template. The explainer reconciles overlapping findings,
resolves contradictions, and weaves the slices into a unified picture.

### 4. Present

Present the explainer's output to the user. Light edits for clarity and context
from the conversation are fine. Do not rewrite it substantially. The explainer's
communication is the product.

## Output Format

Follow this structure, adapted to the question. Not every section is needed for
every question.

- **Overview**: 1-2 paragraphs. What it is, what it does, why it exists. Enough
  for the reader to decide whether to keep reading.
- **Key Concepts**: The important types, services, or abstractions, each with a
  brief definition. Not exhaustive. Include only the concepts needed to
  understand the rest.
- **How It Works**: The core of the explanation. Walk through the flow: what
  triggers it, what happens step by step, where data goes, and the decision
  points. Use prose, not pseudocode. Reference specific files and functions so
  the reader can go look. Do not dump code blocks unless a snippet is necessary.
- **Where Things Live**: A brief map of the relevant files and directories.
  Include only the ones needed to start working in this area.
- **Gotchas**: Non-obvious or surprising behavior that would trip someone up.
  Historical context that explains why something looks strange. Known sharp
  edges.

## Critique Mode

Use critique mode when the user asks for architectural issues, problems, or
improvements instead of understanding alone.

### 1. Explain First

Run the full explain flow above, steps 1 through 4. You must understand the
architecture before you critique it.

### 2. Spawn Critics

After the explanation is complete, spawn architectural critics in a single
message. Use one critic per distinct model family or subagent. Escalate
reasoning effort when the architecture warrants deeper analysis.

Read [critic-prompt.md](references/critic-prompt.md) for the prompt template.
Each critic receives:

1. The explanation from step 1, so critics do not re-explore.
2. The relevant file paths, so critics can read the actual code.
3. The rubric from [critique-rubric.md](references/critique-rubric.md).

### 3. Lead Judgment

Apply the same framework as the `interrogate` skill. Act as a pragmatic lead,
not an aggregator.

Categorize findings:

- **Act on**: Architectural problems worth fixing now.
- **Consider**: Real concerns with unclear cost/benefit.
- **Noted**: Valid observations of low priority.
- **Dismissed**: Wrong, missing context, or style preference.

Present the explanation from step 1 first, then the critique verdict below it.
The explanation must stand on its own. A reader who only wants to understand the
system must not have to wade through the critique.
