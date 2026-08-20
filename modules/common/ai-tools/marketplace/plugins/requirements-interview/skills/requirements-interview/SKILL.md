---
name: requirements-interview
description: "Bounded requirements interview for an explicit interview request or unresolved material product choice. Discover facts first, then ask frontier questions with recommendations. Do not use for routine clarification."
license: Complete terms in LICENSE
---

# Requirements Interview

Use this skill to resolve material product choices through a bounded interview.

## Trigger

Activate only when the user asks for a requirements interview, grilling, or
stress test, or when a material product decision remains unresolved. Do not
activate for routine implementation, generic clarification, or architecture
owned by another skill.

## Method

- Discover facts and run cheap probes before asking questions. Never ask the
  user for facts available from the repository or connected tools.
- Model decisions as a tree. Ask the complete current frontier in one round.
- Give each bounded question a recommendation and the reason for it.
- Wait for answers before asking questions that depend on them.
- Stop when the frontier is empty and shared understanding is confirmed.

Read [interview-method.md](references/interview-method.md) for the question
format, frontier rules, authority boundary, and artifact contract.

Do not write an ADR, requirements document, plan, code, commit, review, pull
request, or other project artifact unless the user explicitly requests that
output.
