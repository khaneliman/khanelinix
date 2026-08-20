# Iterative Hillclimbing

Hillclimbing systematically improves a measurable metric through successive
single-variable experiments.

## Core Rules

- **One metric.** Define a single target metric and direction of improvement.
- **Freeze the harness.** Validate benchmark sensitivity, then freeze the
  measurement harness code.
- **One change per iteration.** Measure each change before starting another.
- **Keep or restore.** Retain verified improvements. Restore only experiment
  changes owned by this run after neutral results or regressions.
- **Data decides.** Benchmark evidence supports each successful optimization.

## Workflow

1. **Ground the workload.** Identify realistic workload dimensions including
   payload size, concurrency, and volume.
2. **Set stop predicate.** Pair a target performance goal with a minimum attempt
   floor to prevent premature stopping.
3. **Execute iterations.**
   - Formulate one hypothesis.
   - Apply one code change.
   - Run benchmark harness.
   - Record baseline number, new number, and delta.
   - Keep the change if improved. Restore the owned experiment if unchanged or
     regressed.
4. **Handle plateaus.** When improvements stall:
   - Pivot to a different strategy family.
   - Combine near-miss ideas.
   - Inspect source for structural simplifications.
5. **Terminate.** Stop when the declared predicate is satisfied or the recorded
   hypothesis set is exhausted.
