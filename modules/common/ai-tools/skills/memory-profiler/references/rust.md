# Rust Memory Profiling & Optimization

Rust enforces memory safety strictly at compile-time without a runtime garbage
collector. However, logic leaks and severe heap fragmentation caused by
suboptimal allocator behavior can still occur.

## Profiling Tools & Diagnostic Workflows

### Jemallocator

- **Use Case**: Mitigates severe fragmentation in highly-concurrent setups;
  features built-in continuous heap profiling (via `rust-jemalloc-pprof`).
- **Overhead**: Negligible (~2%).
- **Workflow**: Implement the `tikv_jemallocator` crate and assign
  `jemallocator::Jemalloc` as the `#[global_allocator]` via feature flags
  (`#[cfg(feature = "jemalloc")]`).
- **Benefit**: Drop-in refactoring to resolve "stair-step" memory profiles and
  continuous fragmentation.

### Dhat

- **Use Case**: Block-level heap analysis, continuous tracking of peak memory
  consumption.
- **Overhead**: Significant degradation. Use only in isolated testing.
- **Workflow**: Assign `dhat::Alloc` as global allocator. Generates
  `dhat-heap.json` viewed in `dh_view.html`.
- **CI/CD Integration**: Write unit tests asserting peak memory utilizing
  `dhat::Profiler::builder().testing()` framework to automatically fail PRs
  introducing unbounded memory growth.

## Refactoring Strategies and Optimizations

- **`std::collections::HashMap`**: Avoid unbounded caches. Employ bounded caches
  (e.g., `lru` crate) to cap memory.
- **Deep cloning (`.clone()`)**: Leverage `std::borrow::Cow<T>` for
  Clone-on-Write semantics.
- **Frequent small `Vec<T>`**: Utilize `SmallVec` or `ArrayVec` to
  stack-allocate collections with known small maximum capacities.
- **Massive file reading into RAM**: Transition to memory mapping to avoid
  duplicating data.
- **Duplicated immutable strings**: Implement `CompactString` or intern
  repetitive strings.
- **Dynamic Collection Sizing**: Pre-allocate sizes via
  `Vec::with_capacity(size)`.
- **Shared Ownership**: Use `Arc<T>` strictly but cautiously, as reference
  cycles leak memory permanently.
