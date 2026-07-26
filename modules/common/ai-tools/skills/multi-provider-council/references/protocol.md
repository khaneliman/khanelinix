# Council Protocol

## Contents

- [Boundaries](#boundaries)
- [First Round](#first-round)
- [Response Contract](#response-contract)
- [Synthesis](#synthesis)
- [Challenge Round](#challenge-round)
- [Durable State](#durable-state)
- [Approval and Execution](#approval-and-execution)
- [Failure Semantics](#failure-semantics)

## Boundaries

Council agents deliberate only. Keep them read-only and narrowly scoped. Parent
gathers facts, verifies evidence, resolves conflicts, writes the plan, and owns
final judgment. Approved implementation remains the delivery workflow's job.

Do not create a shared agent chat. Independent first-round answers reduce
anchoring and provider conformity while allowing concurrent dispatch.

## First Round

Give every seat the same compact packet:

- objective and success criteria;
- audience and intended endpoint;
- verified facts, relevant paths, and supplied artifacts;
- in-scope and out-of-scope boundaries;
- constraints, risk class, and read-only tool lane;
- requested perspective and response contract;
- exact exit criteria.

Use the canonical seats from delivery routing. Confirm the native agent type is
available before dispatch. Installed names do not prove live authentication; the
first bounded dispatch is the route health check.

## Response Contract

Request one compact Markdown evidence packet:

```markdown
## Recommendation

## Evidence

## Assumptions

## Alternatives and Tradeoffs

## Risks and Edge Cases

## Blocking Objections

## Confidence
```

Require repository claims to include paths and external claims to identify their
source. Do not request hidden chain-of-thought or persist raw worker
transcripts.

Suggested caps: 1,200 words and eight read-only tool calls in round one; 500
words and four calls in a challenge response. Harness limits override these
proxies when stricter controls exist.

## Synthesis

Parent verifies load-bearing claims and creates this issue matrix:

| Issue | Raised by | Evidence | Agreement | Disposition | Blocking |
| ----- | --------- | -------- | --------- | ----------- | -------- |

Do not count votes. Prefer evidence, constraint fit, reversibility, and explicit
user intent. Preserve credible dissent even when parent chooses another option.

Synthesis is ready when:

- at least two distinct providers returned usable packets;
- every blocking objection is resolved, accepted by the user, or surfaced as a
  decision that prevents execution;
- load-bearing claims are verified;
- missing providers and residual uncertainty are disclosed.

Begin the user-facing result with this council status and seat receipt:

```text
Council status: <complete|degraded|unavailable>
Seats: Anthropic opus-5=<seat-status>; Google gemini-3-1-pro=<seat-status>; OpenAI gpt-5-6-sol=<seat-status>
```

Replace placeholders rather than printing them literally. Use `complete` for
three usable packets, `degraded` for two, and `unavailable` for fewer than two.
Use `usable` or `unavailable (<reason>)` for each seat, then follow with the
synthesis and any missing-provider caveat.

## Challenge Round

Skip round two when recommendations materially align. Otherwise send affected
seats only the normalized issue matrix and ask for:

- factual correction;
- strongest unresolved objection;
- required plan change;
- whether the objection blocks execution and why.

Run this once. Persistent disagreement becomes a parent or user decision, never
an open-ended debate loop.

## Durable State

Answer-only work may stay ephemeral. Use planning-with-files for multi-phase,
high-risk, implementation, or explicitly durable work.

- `progress.md`: provider, route, status, attempts, failure, current phase.
- `findings.md`: normalized packets, verified evidence, issue matrix, dissent,
  and missing-provider caveats.
- `task_plan.md`: synthesized plan, exact mutation scope, validation, rollback,
  and approval boundary.

Never store raw transcripts. Re-read all three files after compaction or resume.

## Approval and Execution

Before tracked source edits or external writes:

1. Capture relevant Git baseline and existing dirty paths.
2. Write exact plan, allowed paths, validation, and rollback expectations.
3. Ask explicitly whether that exact plan and scope are approved for mutation.
4. After approval, attest the unchanged plan with planning-with-files.
5. Record approval, attested plan hash, baseline, and scope in `progress.md`.

Plan edits, scope changes, or relevant baseline drift invalidate approval. After
approval, invoke delivery-workflow and any domain skill required by the task.
Commit, push, merge, publish, and pull-request actions still need their normal
explicit authority.

## Failure Semantics

- Unknown agent type: provider seat is unavailable on this harness.
- Authentication, connection, or throttle failure: record provider failure; do
  not mislabel it as a routing or reasoning failure.
- Malformed packet: request one format-only repair without adding new analysis.
- One failed provider: continue with two and mark synthesis degraded.
- Two failed providers: do not claim council consensus.
- Relevant source drift: revalidate affected evidence before synthesis or
  invalidate approval before execution.
- Retry the same route at most once, only with materially new evidence or a
  different route condition. Honor the repository retry circuit breaker.
