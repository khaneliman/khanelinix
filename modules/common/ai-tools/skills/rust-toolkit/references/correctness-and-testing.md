# Rust Correctness and Testing

Match validation to the changed contract. Prefer durable invariants over tests
that freeze incidental formatting, timing, allocation counts, or implementation
shape.

## Validation Ladder

Use the smallest rung that can disprove the change, then widen by risk:

1. existing repository-specific formatter, generator, or lint command
2. focused package/target `cargo check`
3. focused unit or integration test
4. workspace checks across supported targets and feature combinations
5. Clippy and rustdoc with the repository's configured lint policy
6. specialized tools for unsafe, concurrency, fuzz, or platform behavior
7. release-mode, end-to-end, or deployment-target proof

Do not introduce `-D warnings` ad hoc when the repository does not own that
policy. New compiler versions can turn unrelated warnings into failures.

## Test Placement

- Keep private implementation tests beside the module.
- Use `tests/` for public API and cross-module behavior.
- Use doctests for user-facing examples that are part of the API contract.
- Keep compile-pass/fail fixtures for macro expansion, trait bounds, and
  typestate misuse where compiler acceptance is the behavior under test.
- Put platform, database, network, or process tests behind explicit harnesses;
  do not disguise integration tests as isolated unit tests.

Test state transitions, ownership, lifecycle, safety, serialization round trips,
and error classification. Avoid exact error prose, debug output, thread
interleavings, benchmark thresholds, or rendering offsets unless explicitly
contractual.

## Technique Selection

| Risk                                       | Technique                                |
| ------------------------------------------ | ---------------------------------------- |
| Broad input space and algebraic invariants | Property tests                           |
| Parser/protocol equivalence                | Model or differential tests              |
| Panic, crash, or malformed input           | Coverage-guided fuzzing                  |
| Unsafe aliasing and validity               | Miri plus targeted unit tests            |
| Lock-free or synchronization interleavings | Loom/model checking                      |
| FFI and memory corruption                  | Sanitizers/Valgrind-style platform tools |
| API misuse should not compile              | Compile-fail tests                       |
| Performance regression                     | Criterion or stable scenario benchmark   |

Use these tools only on supported targets/toolchains. Keep seed corpora, models,
and failing regressions small enough to live with the code.

## Unsafe Review

For every `unsafe` block, function, impl, or trait:

1. State the safety invariant immediately beside the boundary.
2. Identify who establishes and who preserves each precondition.
3. Minimize the unsafe region; keep validation and ordinary control flow safe.
4. Check aliasing, initialization, provenance, alignment, layout, lifetimes,
   unwind behavior, thread safety, pinning, and FFI ownership as applicable.
5. Test safe wrappers with edge values; use Miri where its model supports the
   operation.
6. Review `unsafe impl Send/Sync` independently. Interior fields and future
   mutation can invalidate the proof.

Do not claim Miri or sanitizers prove absence of undefined behavior. Record the
covered commands, target, toolchain, and paths.

## Async and Concurrent Tests

- Control time through the runtime's test clock when possible.
- Assert cancellation and shutdown, not only successful completion.
- Bound channel capacity and test backpressure and receiver loss.
- Avoid sleeps as synchronization; use barriers, notifications, or observable
  state transitions.
- Make spawned-task ownership explicit so tests cannot pass while work leaks.
- Use Loom for a reduced model, not the full application. Keep state space
  bounded and convert discovered schedules into regression tests.

## Reporting

Report exact commands and feature/target selection. Separate:

- passed checks
- checks not run and why
- failures caused by the change
- unrelated pre-existing failures
- specialized-tool coverage limitations
