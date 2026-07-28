---
name: multi-provider-sdlc
description: Route software work across native Anthropic, Google, and OpenAI provider or model subagents for planning, architecture, diagnosis, implementation, validation, and review. Use for explicit multi-provider, all-provider, council, cross-model, subscription-aware, delegated delivery, or end-to-end SDLC requests. Mutation requests execute through completion; plan-only and review-only are endpoints the user must name.
---

# Multi-Provider SDLC

Execute the user's endpoint, not an intermediate plan. Use only current-harness
native subagents.

## Endpoint

- Mutation request: plan, implement, validate, review, correct, and finish.
- Plan, answer, or review only: stop there only when explicitly requested.
- A plan or deliberation does not create an approval checkpoint. Pause only for
  missing authority, material scope expansion, or an unresolved blocking choice.
- Use planning-with-files only when persistence helps. Default to autonomous
  mode; use gated mode only when explicitly requested.

## Playbook Index

Read [routing](references/routing.md) before delegation, then only playbooks
needed for the requested endpoint:

- Plan, architecture, diagnosis, brainstorming, or council:
  [deliberation](references/deliberation.md)
- Implement, fix, refactor, migrate, or integrate:
  [implementation](references/implementation.md)
- Reproduce, test, build, lint, or validate:
  [validation](references/validation.md)
- Plan, diff, code, or final quality review: [review](references/review.md)

For end-to-end mutation, read implementation, validation, and review. Add
deliberation when explicitly requested or valuable for high-risk decisions.

Give workers only task, paths, constraints, allowed lane, and exit criteria.
Preserve unrelated work. Never auto-commit, tag, merge, push, publish, or open a
pull request.
