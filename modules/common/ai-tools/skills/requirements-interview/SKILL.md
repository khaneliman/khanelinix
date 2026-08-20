---
name: requirements-interview
description: "Run a bounded requirements interview for an explicit interview request or an unresolved material product choice. Discover facts and run probes first, then ask one frontier round at a time with recommendations. Do not write an ADR or requirements artifact unless explicitly requested. Do not own implementation, review verdicts, commits, or pull requests."
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
