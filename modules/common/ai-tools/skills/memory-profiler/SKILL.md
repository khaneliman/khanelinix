---
name: memory-profiler
description: Diagnose memory inefficiencies, capture high-resolution memory profiles, and execute architectural refactoring across C++, Rust, TypeScript/Node.js, .NET, and Python. Use when troubleshooting memory leaks, out-of-memory (OOM) errors, or heap fragmentation.
---

# Memory Profiler

This skill establishes an exhaustive framework for diagnosing memory
inefficiencies, capturing memory profiles, and executing architectural
refactoring across various programming languages.

## Core Concepts

- **Memory Wall**: Speed and efficiency are constrained by memory spatial
  locality, access patterns, and allocation overhead.
- **Fragmentation**: Frequent allocations/deallocations cause heap memory to
  fragment, forcing OS to allocate additional pages.
- **Data-Oriented Design (DOD)**: Refactoring from Array of Structures (AoS) to
  Structure of Arrays (SoA) guarantees homogenous data fields are packed
  tightly, optimizing CPU cache usage and minimizing RAM latency.

## Language Specific Guides

For instructions on memory profiling, tooling workflows, and refactoring
strategies for a specific language, load the corresponding reference document:

- **C++**: See [references/cpp.md](references/cpp.md) for Valgrind, Heaptrack,
  Memory Pools, and SSO.
- **Rust**: See [references/rust.md](references/rust.md) for Jemallocator, Dhat,
  Collection Bounding, Cow, and Arc.
- **TypeScript & Node.js**: See [references/node.md](references/node.md) for V8
  Inspector, Clinic.js, Object Pooling, and Closure scope mitigation.
- **.NET (C#)**: See [references/dotnet.md](references/dotnet.md) for
  dotnet-counters, dotnet-gcdump, ArrayPool, and struct conversions.
- **Python**: See [references/python.md](references/python.md) for Tracemalloc,
  Memray, `__slots__`, Generators, and String Interning.

Use these files to perform high-level memory analysis, locate leaks, and apply
the appropriate refactoring pattern.
