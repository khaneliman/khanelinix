# One-Off Performance Optimization

Follow a strict measurement loop when resolving a performance issue. Every
optimization must connect directly to measured profile evidence.

## Strategy Families

Use these eight strategy families to generate hypotheses from profile artifacts.
Apply a strategy only when measurement data shows the matching bottleneck.

1. **Elimination.** Delete work that is never consumed. Check for dead feature
   checks, redundant serialization, or unused computed properties.
2. **Divide and Conquer.** Partition large workloads into smaller units. Split
   inputs, prune search trees, or run independent chunks concurrently.
3. **Caching.** Reuse previously computed deterministic results. Always define
   explicit cache invalidation conditions before applying caching.
4. **Indirection.** Introduce intermediate structures to absorb expensive work.
   Use index lookups, memory handles, or background processing queues.
5. **Batching.** Combine multiple fine-grained operations into one batch.
   Coalesce remote procedure calls, database queries, and filesystem writes.
6. **Redundancy.** Execute speculative parallel attempts when tail latency
   dominates and excess capacity exists. Select the fastest response.
7. **Lazy Evaluation.** Defer expensive computation until the result is first
   requested. Avoid eager initialization during startup paths.
8. **Scheduling.** Move required work off the interactive latency path. Shift
   operations to idle callbacks, warmup steps, or background workers.

## Optimization Loop

1. **Capture baseline.** Record the baseline metric and store the profiler
   artifact.
2. **Select one family.** Choose the strategy family that directly addresses the
   dominant hotspot.
3. **Make one change.** Apply the smallest focused code modification.
4. **Capture post-fix artifact.** Run the exact same workload and record new
   metrics.
5. **Compare artifacts.** Diff the before and after measurements.
6. **Handle inconclusive results.** If the difference is within noise
   thresholds, mark the run inconclusive and revert.
