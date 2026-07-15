# Rust Performance

Optimize from evidence. Keep compile-time, runtime latency, throughput, memory,
binary size, and developer iteration as separate budgets.

## Measurement Contract

Before changing code or configuration, record:

- workload, inputs, target, feature set, profile, toolchain, and hardware
- clean or incremental build state
- warmup and sample strategy
- metric and variance
- profiler or Cargo timing evidence locating the dominant cost

Change one meaningful variable. Re-run the same command shape. A faster debug
build does not prove a release workload improved; a microbenchmark does not
prove end-to-end latency improved.

## Runtime Ladder

1. Verify algorithmic complexity and unnecessary work.
2. Profile representative release-like execution.
3. Improve data flow, batching, locality, and allocations at the hot path.
4. Remove contention or oversubscription.
5. Tune code generation, target CPU, or allocator only after the previous layers
   are measured.

Prefer data layouts that match traversal. Avoid cloning to satisfy ownership
without showing where ownership should move or borrowing should narrow. Treat
`unsafe` optimization as a proof obligation with benchmarks and correctness
tests.

## Allocation Decisions

- Start with the platform allocator.
- Profile allocation count, size distribution, lifetime, fragmentation, RSS, and
  contention before replacing it.
- Benchmark global allocators against the real workload. jemalloc, mimalloc, and
  the system allocator trade throughput, latency, memory footprint, platform
  support, and observability differently.
- Use arenas/bump allocation when a batch has one clear lifetime and bulk drop
  matches semantics. Account for destructors, retained capacity, references
  escaping the arena, and peak memory.
- Prefer object reuse or stack/small-buffer layouts only when profiles show
  allocation pressure and complexity remains bounded.

Never promise an allocator improvement from reputation. Include before/after
numbers and revert the dependency/configuration when gain is not material.

## Compile-Time Ladder

1. Use Cargo timings to identify expensive crates and build scripts.
2. Remove unused dependencies/features and duplicate versions carefully.
3. Reduce macro/generic/codegen fan-out at proven hot boundaries.
4. Check whether workspace feature selection causes repeated dependency builds.
5. Consider crate splits only when they isolate stable code from frequent
   recompilation without creating high-churn APIs.
6. Evaluate linker, cache, codegen backend, and profile changes per target.

Do not run clean builds repeatedly when the user cares about edit-build-run
latency. Measure both clean and representative incremental paths.

## Profiles and Toolchain Choices

- Keep dependency optimization and local-code optimization separate when a debug
  workload is too slow, but measure initial and incremental compile cost.
- Preserve debug assertions and overflow checks where development behavior
  depends on them.
- Treat alternative linkers as target-specific. Native libraries, debug info,
  sanitizers, platform SDKs, and CI images can constrain the choice.
- Treat nightly compiler threads, Cranelift, and unstable Cargo settings as
  experiments with explicit fallback, not default project requirements.
- Use dynamic linking for development only when platform support, deployment,
  and measured iteration gains justify added complexity.
- Configure shared caches with reproducibility, credentials, cache poisoning,
  and CI eviction behavior visible.

Official starting point:
[Cargo build-performance guidance](https://doc.rust-lang.org/cargo/guide/build-performance.html).

## Output

Return a compact table containing baseline, change, result, variance, and
tradeoff. Separate recommendations not yet measured from verified gains.
