---
name: multi-provider-sdlc
description: Resolve a task type to a model, worker, and effort with a structured routing script. Use for model selection, provider constraints, or route retries. Caller owns lifecycle and final judgment.
metadata:
  disable-model-selection: "true"
---

Call `python3 <skill-root>/scripts/route-model.py` with JSON on stdin. Use
`--schema` for accepted values and constraints. Do not read routing tables.

`{ "task_type": "implementation", "provider": "codex", "gateway": false }`

Set `provider` from the current harness. Use `gateway: false` unless this
invocation explicitly uses a gateway route; a running gateway service does not
enable routing. Optional `subscription` constrains selection; optional `state`
reuses task-local quota evidence. Never omit existing state to bypass a blocked
route.

In T3, call `orchestrator_capabilities` and pass its live result as
`capabilities`, with `gateway: false`. The resolver returns a native `target`
for `delegate_task`, not a local named agent. Narrow provider instances when
needed to match the intended account; quota state must describe those accounts.
Without T3 capabilities, native selection uses the current CLI's semantic
profile and cannot switch subscriptions. Gateway selection needs configured
gateway model agents; it does not create them or change a native invocation.

For optional quota advice:
`python3 <skill-root>/scripts/quota-advice.py --provider <codex|claude|antigravity>`.
Match its account to the route; add `--user-requested` for more workers or a
swarm. Missing CodexBar never blocks dispatch.

Follow `next_action`: complete `claim_argv` before any stateful dispatch. For a
`target`, call `delegate_task` and retain its task ID; manage it through
`task_status`/`task_cancel`. Otherwise dispatch `agent_type` without a model
override and pass supported non-null `reasoning_effort`. Record every claimed
attempt through `record_argv`; native attempts cannot report named-agent errors.
Preserve `semantic_role` and `write_policy` in the packet. A catalog is not
proof of quota or successful inference. Selection grants no new authority.
