---
name: delivery-workflow
description: Provider-neutral delivery workflow for quality-first native subagent routing, subscription-aware model selection, bounded implementation, validation, and review. Use when user requests delivery workflow, multi-model delegation, cross-provider workers, or balanced subscription usage.
---

# Delivery Workflow

Use current harness's native subagent mechanism. Never invoke another AI harness
through shell, CLI, MCP, or wrapper script.

Read [routing and gates](references/routing.md) before dispatch.

## Loop

1. Read contributor canon and inspect dirty state. Preserve unrelated work.
2. Classify task `trivial`, `normal`, or `high-risk` using routing reference.
3. State assumptions and planned route. User owns architecture and scope.
4. Choose smallest capable model agent. Prefer provider different from parent
   when suitability is equal.
5. Dispatch listed model-agent name as native agent type. Do not pass a model
   override: installed definition pins gateway model. When model agents or
   gateway are unavailable, use listed semantic role or one native generic
   worker with same scope, permissions, and exit criteria. Never emulate missing
   native delegation by launching another harness.
6. Keep planning, integration, architecture, and final judgment in parent.
7. Validate proportionally. Use fresh reviewer where risk gate requires it.
8. Apply bounded corrections, then rerun fresh review at most once.

Give workers only task, paths, constraints, allowed tool or skill lane, and exit
criteria. Consume compact evidence packets or changed-file summaries. Do not
duplicate work solely to balance quotas.

Never auto-commit, tag, merge, push, publish, or open pull request. Handoff only
changed-file summary, validation, review verdict, residual risk, and suggested
commit boundaries.
