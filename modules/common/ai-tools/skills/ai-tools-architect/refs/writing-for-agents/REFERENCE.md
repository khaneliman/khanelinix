# Writing for Agents

Use this reference to place and write instructions that an agent consumes.
`ai-tools-architect` owns placement and routing. `skill-creator` owns package
structure. `technical-writing` owns human-facing clarity and fact retention.

## Context Pointers

A context pointer names gated material and states when to load it. Skill
descriptions and scoped instruction links are context pointers.

Write each pointer to do two jobs:

1. State what the target owns.
2. Name each distinct trigger branch.

Front-load the term that should match the request. Keep one trigger for each
branch. Remove synonyms that repeat one branch. If required material is missed,
sharpen its pointer before moving the full content into always-loaded context.

## Two Load Budgets

- **Context load** is material carried on every turn. Examples include root
  instructions and model-invoked skill descriptions.
- **Cognitive load** is what the user must remember and invoke. Explicit-only
  workflows spend this budget to avoid permanent context load.

Spend context load when agents must discover a route naturally. Spend cognitive
load when explicit human intent is a useful gate. A host-only or consequential
workflow often benefits from an explicit gate.

## Information Hierarchy

Place material at the highest tier that needs it:

1. **In-file steps:** ordered actions required on every run.
2. **In-file reference:** compact rules consulted by most branches.
3. **Disclosed reference:** branch-specific rules behind a precise pointer.

Inline shared steps. Disclose branch-specific reference. Keep definitions,
rules, and caveats for one concept together after placement. If every line is
relevant but the file is still long, split by branch or sequence.

## Completion Criteria

End each step with a condition that is both checkable and demanding. Name the
artifact, observation, or exhaustive set that proves completion.

- Weak: "Review the callers."
- Checkable: "Account for every caller returned by the repository search."
- Weak: "Verify the change."
- Checkable: "Run the command that fails when this behavior is wrong."

Sharpen the criterion before adding more procedure. Split a sequence only when
later visible steps repeatedly cause premature completion of the current step.

## Leading Words and Positive Targets

Use one established technical term to anchor one behavior. Reuse that term in
the pointer, body, tests, and surrounding configuration. Define a coined term
only when existing vocabulary cannot carry the distinction.

State the target behavior directly. Reserve prohibitions for hard guardrails,
then pair each prohibition with the behavior the agent should perform.

## Pruning Pass

Review every instruction against these failure modes:

- **No-op:** The model already behaves this way without the line. Delete it.
- **Duplication:** Another co-loaded source owns the same meaning. Keep one
  authority and point to it.
- **Environment cache:** The line copies a cheap lookup from source, config,
  directory structure, or command help. Keep only the non-obvious constraint.
- **Sediment:** The line describes stale behavior or an obsolete branch.
- **Sprawl:** Live material exceeds one useful attention surface. Disclose by
  branch or split the sequence.
- **Scattering:** One concept's definition, rules, and caveats live in several
  places. Co-locate them.

Test disputed no-ops with realistic prompts. Treat changed agent behavior as
evidence. Keep a line only when it improves routing, execution, or completion.

## Attribution

This reference distills concepts from Matt Pocock's `writing-for-agents` skill.
The prose here is original. The adjacent [LICENSE](LICENSE) preserves upstream
MIT terms.
