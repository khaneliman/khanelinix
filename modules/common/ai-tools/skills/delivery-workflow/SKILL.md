---
name: delivery-workflow
description: Provider-neutral delivery workflow for bounded implementation, validation, and fresh review using subscription-aware native subagent routing. Use when the user requests execution of an approved plan, implementation delegation, validation or review cycles, or balanced subscription usage for delivery work. Explicit all-provider deliberation belongs to multi-provider-council.
---

# Delivery Workflow

Use current harness's native subagent mechanism. Never invoke another AI harness
through shell, CLI, MCP, or wrapper script.

Read [routing and gates](references/routing.md) before dispatch.

When the user explicitly requests all-provider deliberation, a multi-model
council, parallel perspectives, or comparison of independent plans, invoke
`multi-provider-council` before this loop. Resume delivery only from its
approved plan; do not repeat council deliberation during implementation.

Before mutation from a council handoff, re-read the active `task_plan.md` and
`progress.md`. Verify explicit approval is recorded, plan attestation is
current, and relevant baseline and allowed scope have not drifted. Stop for
renewed approval when any check fails.

## Loop

1. Read contributor canon and inspect dirty state. Preserve unrelated work.
2. Classify task `trivial`, `normal`, or `high-risk` using routing reference.
3. State assumptions and planned route. User owns architecture and scope.
4. Choose smallest capable model agent. Resolve provider preference through the
   subscription map, not the agent name, and prefer a subscription other than
   parent's when suitability is equal.
5. Confirm the route exists in the harness's available agent-type list, then
   dispatch that name as native agent type. Do not pass a model override:
   installed definition pins gateway model. When model agents or gateway are
   unavailable, use listed semantic role or one native generic worker with same
   scope, permissions, and exit criteria. Never emulate missing native
   delegation by launching another harness.
6. Keep planning, integration, architecture, and final judgment in parent.
7. Validate proportionally. Use fresh reviewer where risk gate requires it.
8. Apply bounded corrections, then rerun fresh review at most once.

Give workers only task, paths, constraints, allowed tool or skill lane, and exit
criteria. Consume compact evidence packets or changed-file summaries. Do not
duplicate work solely to balance quotas.

Never auto-commit, tag, merge, push, publish, or open pull request. Handoff only
changed-file summary, validation, review verdict, residual risk, and suggested
commit boundaries.
