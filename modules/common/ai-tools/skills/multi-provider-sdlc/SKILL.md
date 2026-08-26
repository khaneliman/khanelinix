---
name: multi-provider-sdlc
description: Select concrete model seats, fallbacks, and quota circuits when provider diversity, a named model, or a route retry matters. Caller owns lifecycle, phase boundaries, and final judgment.
metadata:
  disable-model-selection: "true"
---

# Multi-Provider SDLC

Route one caller-owned phase through current-harness native subagents. This
skill owns provider choice, quota circuits, and bounded worker packets. It does
not own lifecycle sequencing, correction, or final judgment.

For ordinary delegation, use the semantic role from always-loaded context and
skip this overlay. Load it when concrete provider or fallback choice matters.

For one known dispatch, keep capability evidence in the caller packet. When a
task can retry, cross providers, or reuse circuits in later phases, use the
task-local capability state defined in [routing](references/routing.md).

## Ownership

- The caller supplies endpoint, phase, risk, paths, authority, success criteria,
  and exit criteria.
- For provider-diverse mutation, `engineering-workflow` owns phase order and
  completion. This skill returns one phase packet to it.
- For review, `interrogate` or the caller owns method and synthesis. This skill
  selects concrete seats for provider diversity, named-model intent, quota
  fallback, or route retry.
- For an explicit plan-only, council, or review-only request, the user request
  supplies the endpoint.
- A plan does not create an approval checkpoint. Pause only for missing
  authority, material scope expansion, or an unresolved blocking choice.

## Playbook Index

Read [routing](references/routing.md) before delegation, then only the playbook
for the caller-supplied phase:

- Plan, architecture, diagnosis, brainstorming, or council:
  [deliberation](references/deliberation.md)
- Implement, fix, refactor, migrate, or integrate:
  [implementation](references/implementation.md)
- Reproduce, test, build, lint, or validate:
  [validation](references/validation.md)
- Plan, diff, code, or final quality review: [review](references/review.md)

Give workers only task, paths, constraints, allowed lane, and exit criteria.
Preserve unrelated work. Never auto-commit, tag, merge, push, publish, or open a
pull request. Return phase evidence to the caller. Do not advance another phase.
