# Spec Template

Use these fields for a fresh-session handoff. Omit empty optional sections;
retain identity, scope, requirements, verification, and unresolved choices.

```markdown
# <Feature title>

- Spec ID: <stable feature identifier>
- Revision: <integer, starting at 1>
- Status: <draft | ready>
- Sources: <durable document/issue links; summarize conversation-only decisions>
- Code baseline: <repository and revision, when applicable>

## Problem and Outcome

<Current behavior, desired behavior, and affected users or callers.>

## Scope and Non-goals

<What belongs in this change and what explicitly does not.>

## Requirements

- R1: <observable behavior, including relevant failure behavior>

## Decisions and Constraints

<Agreed interfaces, invariants, compatibility constraints, and rationale.
Distinguish current-state evidence from proposed contracts.>

## Verification

- R1: <acceptance evidence, existing test seam, and relevant checks>

## Assumptions and Open Choices

<Label assumptions. For each unresolved choice, state what it blocks. Write
"None" if there are none.>

## Revision Notes

<For updates: decisions changed and downstream artifacts that need rechecking.>
```
