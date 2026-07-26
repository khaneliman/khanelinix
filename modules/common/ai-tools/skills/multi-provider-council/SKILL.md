---
name: multi-provider-council
description: Run a bounded council of independent Anthropic, Google, and OpenAI native subagents, compare their perspectives, preserve dissent, and synthesize an approval-gated plan. Use when the user explicitly asks for all providers, a multi-model council, parallel perspectives, independent plans, cross-provider brainstorming, or comparison before execution.
---

# Multi-Provider Council

Every user-facing council result MUST begin with this receipt:

```text
Council status: <complete|degraded|unavailable>
Seats: Anthropic opus-5=<seat-status>; Google gemini-3-1-pro=<seat-status>; OpenAI gpt-5-6-sol=<seat-status>
```

Replace the council placeholder with one value: `complete` for three usable
packets, `degraded` for two, and `unavailable` for fewer than two. Replace each
seat placeholder with `usable` or `unavailable (<reason>)`.

Use the current harness's native subagent mechanism. Never launch another AI
harness through shell, CLI, MCP, or wrapper scripts.

Read [the council protocol](references/protocol.md) and the delivery workflow's
[routing and gates](../delivery-workflow/references/routing.md) before dispatch.

Canonical seats are Anthropic `opus-5`, Google `gemini-3-1-pro`, and OpenAI
`gpt-5-6-sol`. Council mode uses these fixed perspectives; do not replace them
with cheaper or task-fit workers.

## Workflow

1. Confirm council intent, task objective, risk, scope, constraints, and desired
   endpoint: answer only, planning only, or approved execution.
2. For multi-phase, high-risk, implementation, or explicitly durable work,
   activate planning-with-files in an isolated `.planning/<id>` directory.
3. Build one bounded fact packet. Give every seat the same task-local evidence,
   read-only policy, response contract, and exit criteria. Do not include peer
   answers or the full conversation history.
4. Dispatch the canonical Anthropic, Google, and OpenAI seats concurrently. Pass
   native agent types and omit model overrides.
5. Record each route's result or failure. Continue best-effort, but require two
   distinct provider responses before calling the result a council synthesis.
   Label any missing seat visibly as degraded in the user-facing result.
6. Verify load-bearing claims, normalize responses, and build the issue matrix.
   Parent owns architecture, conflict resolution, and final judgment.
7. Run one challenge round only when material disagreement, unsupported claims,
   or blocking risks remain. Send only the issue matrix to affected seats.
8. Synthesize recommendation, evidence, tradeoffs, resolved objections,
   preserved dissent, missing-provider caveats, and confidence.
9. For mutation, write the exact plan, baseline, allowed scope, and validation.
   Stop for explicit approval. After approval, attest the unchanged plan, record
   the receipt, then hand execution to delivery-workflow and relevant domain
   skills.

## Limits

- Maximum two rounds and six council dispatches.
- No recursive worker delegation, peer-to-peer chat, or raw transcript storage.
- One format-repair attempt for malformed output; then mark that seat failed.
- Never silently replace a failed provider with another model or the parent
  subscription.
- With fewer than two provider results, report council unavailable and continue
  only as ordinary parent reasoning.
