---
name: multi-provider-sdlc
description: Resolve a task type to a model, worker, and effort with a structured routing script. Use for model selection, provider constraints, or route retries. Caller owns lifecycle and final judgment.
metadata:
  disable-model-selection: "true"
---

# Model routing

Call `python3 <skill-root>/scripts/route-model.py` with JSON on stdin. Use
`--schema` for accepted values and constraints. Do not read routing tables.

```json
{ "task_type": "implementation", "provider": "codex", "gateway": false }
```

Set `provider` and `gateway` from the actual harness configuration. Optional
`subscription` restricts gateway selection; optional `state` reuses task-local
quota evidence. Never omit existing state to bypass a blocked route.

Follow the returned `next_action`. Dispatch `agent_type` without a model
override; pass non-null `reasoning_effort` when supported. Preserve
`write_policy` in the worker packet. Selection grants no new authority and does
not verify availability.
