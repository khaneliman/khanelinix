---
name: burn
description: "Host-only quota-burning overlay for maximum useful parallel throughput across providers. Use when explicitly asked to /burn, burn usage, or spend available quota before a reset."
disable-model-invocation: true
metadata:
  khanelinix-invocation-mode: user-only
---

# Burn

Turn available subscription usage into completed, verified work quickly. The
task's normal workflow owns lifecycle, integration, commits, and final judgment;
this overlay owns quota-aware fan-out. Requires `multi-provider-sdlc` and host
delegation tools. Keep state in the task's ignored scratch directory.

## Workflow

1. **Scope the queue.** Use the requested task or backlog and its completion
   criteria. If no work was specified, ask for the task before dispatching. Map
   dependencies and ready slices; keep dependent design and integration with the
   parent. Each slice needs a concrete artifact or check, paths, one write
   owner, and an exit condition. Quota is a resource, not a work target.
2. **Read capacity.** Discover live providers, models, and actual host limits.
   In T3 use `orchestrator_capabilities`; a thread-creation batch limit is not a
   delegated-worker concurrency limit. Disk is a host limit: check free space as
   `git-toolkit` cleanup describes before isolating any worker. Use
   `multi-provider-sdlc` quota advice with `--user-requested` for each relevant
   provider, fetching independent sources concurrently. Match each source to the
   account running the workers. Keep all reported windows, headroom, reset
   times, and available reset-credit inventory. Missing telemetry is unknown,
   not exhaustion or unlimited usage. When `reset-inventory.py` is installed,
   enrich the Codex read with
   `reset-inventory.py codexbar usage --provider codex --source cli --json --no-credits`
   and pipe its JSON to quota advice with
   `--provider codex --from-stdin
   --user-requested`. This optional read
   reports reset credits without redeeming them; skip it when the helper is
   unavailable.
3. **Allocate across subscriptions.** Among capable routed workers, favor
   capacity likely to expire unused before its reset, then replenishable
   capacity with confirmed available reset credits, then other headroom. Check
   longer windows and shared model pools too; raw percentages across providers
   are not comparable token budgets. Use provider preference to break ties, not
   to leave other subscriptions idle. Route every worker, including
   implementers, through `multi-provider-sdlc`, using its `subscription`
   constraint and the live catalog rather than choosing model IDs by hand. Keep
   role effort defaults; burning usage is not a reason to raise effort.
4. **Fill the ready queue.** Dispatch all useful independent slices that current
   provider and host capacity can sustain. Use concurrent tool calls and refill
   slots as workers finish, rather than waiting for a whole wave. There is no
   default worker count or forecast-based conservation ceiling in burn mode.
   Grow until ready work, real throttling, host pressure, free disk, or parent
   integration throughput becomes the constraint. For unknown capacity, let one
   required task probe each provider/pool, then expand after success. Give an
   isolated worktree only to a writer that cannot share the checkout; reviewers,
   playtesters, planners, and other readers never get one. Record each worktree
   before dispatch, and commit required inputs first because T3 worktrees start
   from the parent commit. A slot frees only after its worktree closes.
5. **Keep the parent productive.** Give workers bounded packets with task,
   paths, verified context, constraints, write policy, skill/tool lane, required
   evidence, and exit criteria. Integrate and verify returned slices while other
   workers run. Close out each slice's worktree through `git-toolkit` cleanup as
   soon as the slice resolves, before refilling its slot. Avoid overlapping
   writers, duplicate investigations, and extra review rounds without an
   unresolved question. Reserve enough capacity to finish integration and
   corrections, not an arbitrary quota percentage.
6. **React to actual limits.** Retain task-local routing state, claims, task
   IDs, worktree ownership records, and outcomes. Before each refill, compare
   `git worktree list` with those records. An unrecorded worktree, or a resolved
   one still open, blocks expansion until it is closed out. Low disk is a hard
   stop for isolated dispatch until resolved worktrees are closed out. On
   exhaustion, route remaining ready work to another capable subscription
   instead of trying another model in the same pool. Refresh quota before
   substantial expansion and after a confirmed reset. A reset credit being
   available or a reset timestamp passing does not prove replenishment. Redeem a
   credit only when the user authorized redemption and a supported mechanism
   exists; never purchase credits implicitly. Otherwise report the available
   reset while continuing work on other providers. After account-matched fresh
   telemetry or an explicit user report confirms replenishment, use
   `multi-provider-sdlc`'s `reset-quota` recovery procedure once for that reset.
   This rearms one pool for a required probe and preserves other failures. Treat
   rate throttling separately from exhausted allowance; honor retry timing and
   reduce pressure on the affected route.
7. **Finish the work.** Stop adding workers when the authorized queue is done,
   all capable routes are genuinely blocked, or the user stops the run. Collect
   and inspect every result, complete verification, and close out every recorded
   worktree; none may remain open after the run. Report completed work, provider
   distribution, observed usage where available, retained branches with their
   tips, and any remaining blocker. Never invent usage or claim a speedup
   without measurements.
