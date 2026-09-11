---
name: how
description: "Explain a subsystem through direct codebase exploration. Use for how-it-works questions, walkthroughs, caller discovery, placement, or layering decisions."
---

# How

Explain actual behavior from code and caller evidence. Give the reader a working
mental model, not annotated source. When called inside another lifecycle, return
the traced evidence to that owner without starting another workflow.

## Scope and Explore

Identify the subsystem, feature flow, runtime trace, or placement question.
Resolve facts from code and tools. State a reasonable scope assumption when the
request permits it; ask only when a material choice cannot be resolved safely.
Reuse current evidence rather than repeating an exploration already completed.

- **Simple:** trace and explain directly in the parent. Delegation is optional
  when one bounded lookup would materially reduce context or latency.
- **Complex:** split independent facts into bounded read-only explorer packets.
  Keep tightly coupled reasoning and synthesis in the parent. Do not create
  overlapping searches or a separate synthesis worker merely to satisfy phases.

Use [explorer-prompt.md](references/explorer-prompt.md) for delegated discovery.
Each packet names its paths, question, constraints, required evidence, and exit
criteria. Give only the relevant facts, not the conversation history.

## Synthesize

Inspect returned paths and verify claims that determine the explanation.
Reconcile contradictions and distinguish observed behavior from inference.
The parent owns the conclusion and may substantially correct or rewrite worker
output. Never forward an unverified worker explanation as the final product.

Use [explainer-prompt.md](references/explainer-prompt.md) for explanation shape.
Scale the output to the question; a small helper does not need a subsystem report.

## Critique When Requested

For architectural issues or improvement requests, establish the current model
before critique. Reuse the explanation above or existing verified grounding.
Use [critique-rubric.md](references/critique-rubric.md) to frame one fresh reviewer;
[critic-prompt.md](references/critic-prompt.md) supplies its evidence contract.
Escalate to `interrogate` for contested, high-risk, or explicit multi-angle review,
not every architectural question.

The parent classifies findings as act on, consider, noted, or dismissed, with
reasons. Present the explanation and any requested critique verdict. Return to
the caller when this skill is only a grounding method.
