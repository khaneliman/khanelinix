# Interview Method

Use this reference for an explicit requirements interview or an unresolved
material product choice.

## Fact Before Decision

Separate environmental facts from user decisions:

1. Inspect repository files, existing behavior, constraints, and available
   tools.
2. Run a cheap read-only probe when it can settle a factual question.
3. Ask only decisions that remain after the facts are known.

Do not ask the user to retrieve facts that the environment can provide. Treat
tool output as evidence, not as a decision.

## Frontier Rounds

Represent each decision as a node with prerequisites. The frontier contains
nodes whose prerequisites are settled. Ask all frontier nodes in one round.
Defer dependent nodes to a later round.

Use this format:

```text
Q1 - <question title>: <bounded question with concrete choices>

Recommended: <choice>
Reason: <short evidence-based reason>
```

Keep each round small enough to answer in one reply. Include a recommendation,
but make the user the authority for product choices. State assumptions and
tradeoffs. Do not use relentless questioning as a substitute for evidence.

## Authority Boundary

- Agent: gather facts, run probes, map dependencies, expose tradeoffs, and
  summarize the current decision tree.
- User: choose product outcomes, priorities, constraints, and acceptable risk.
- Implementer or project owner: decide execution details after requirements are
  confirmed.

Do not silently resolve a material product choice. If the user cannot answer a
question, record it as open and explain the consequence.

## Completion and Artifacts

The interview completes when every branch is settled or explicitly accepted as
open, and the user confirms shared understanding. Return a concise decision
summary, assumptions, open questions, and next owner.

Write an ADR or requirements artifact only after an explicit request. Confirm
the exact path or repository convention before writing. Verify that the artifact
contains decisions, rationale, constraints, open questions, and no unapproved
implementation commitments.
