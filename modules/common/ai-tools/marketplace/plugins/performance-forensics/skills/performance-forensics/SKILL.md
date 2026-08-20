---
name: performance-forensics
description: Measured performance diagnosis or improvement for latency, CPU, throughput, I/O, contention, traces, or hillclimbing. Read-only diagnosis by default. Use memory-profiler for leaks, OOM, or heap fragmentation.
license: Complete terms in LICENSE
---

# Performance Forensics

Use this skill for empirical performance diagnosis and optimization. Performance
engineering requires measurement artifacts instead of speculative code
inspection.

For memory leaks, out-of-memory errors, and heap fragmentation, use
`memory-profiler`.

## Modes of Operation

Select the mode that matches the task trigger:

- **Live process diagnosis**: Inspect active spinning processes, thread
  contention, or I/O stalls. Read
  [references/runtime-forensics.md](references/runtime-forensics.md).
- **Static trace diagnosis**: Analyze captured profiles, CPU dumps, spindumps,
  and traces. Read
  [references/trace-forensics.md](references/trace-forensics.md).
- **One-off optimization**: Resolve a specific latency, throughput, or CPU
  bottleneck. Read [references/perf-issue.md](references/perf-issue.md).
- **Iterative hillclimbing**: Optimize a metric across multiple experimental
  cycles. Read [references/hillclimb.md](references/hillclimb.md).

## Diagnosis Workflow (Read-Only Default)

Diagnosis tasks are read-only by default. Do not mutate production code during
diagnosis unless requested.

1. **Capture evidence.** Obtain a CPU profile, trace, or execution log using a
   realistic workload.
2. **Reduce artifacts.** Query the profile to identify the dominant bottleneck
   or hot call tree.
3. **Confirm the mechanism.** Verify the bottleneck on the running target before
   proposing changes.
4. **Attribute to source.** Map the hotspot to the exact file, symbol, and line
   number.
5. **Report findings.** Provide the diagnosis, source location, and artifact
   paths.

## Optimization Workflow

When authorized to mutate code, follow this measurement loop:

1. **Ground the workload.** Define a representative workload matching real input
   distributions.
2. **Establish baseline.** Capture baseline metrics and profile artifacts. Save
   the artifact path.
3. **Formulate single hypothesis.** Pick a targeted strategy from the eight
   strategy families in [references/perf-issue.md](references/perf-issue.md).
4. **Apply isolated change.** Modify only the code related to the selected
   hypothesis.
5. **Measure post-fix result.** Run the identical workload. Compare the new
   artifact against baseline.
6. **Evaluate outcome.** Keep confirmed improvements. Restore only experiment
   changes owned by this run after regressions or neutral results. Flag
   inconclusive measurements.
7. **Iterate or stop.** For sustained optimization, follow the stop rules in
   [references/hillclimb.md](references/hillclimb.md).

## Reporting Contract

For diagnosis, return the workload, baseline artifact, source attribution, and
status. For authorized optimization, also return:

- Workload description and parameters.
- Post-fix measurement number and artifact path.
- Net delta percentage or throughput difference.
- Status classification: improvement, regression, or inconclusive.

## Attribution

Adapted from upstream pstack performance and forensics playbooks. See
[LICENSE](LICENSE).
