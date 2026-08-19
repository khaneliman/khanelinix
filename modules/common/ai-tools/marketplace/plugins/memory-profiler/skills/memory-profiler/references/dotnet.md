# .NET Memory Profiling & Optimization

The .NET CLR features a generational garbage collector with a specialized Large
Object Heap (LOH) for allocations > 85,000 bytes. Memory leaks happen when
objects are retained by static caches or lingering event handlers.

## Profiling Tools & Diagnostic Workflows

### dotnet-counters

- **Workflow**: Use to empirically confirm leaks before intensive debugging.
- **Command**:
  1. `dotnet-counters ps` (find Process ID).
  2. `dotnet-counters monitor --refresh-interval 1 -p <PID>`
- **Analysis**: Check `GC Heap Size` and `Committed Size`. If memory
  continuously trends upward and never recovers to baseline post-GC, a leak is
  verified.

### dotnet-gcdump vs. dotnet-dump

- **dotnet-dump**: Captures full 4GB+ core dumps. Analyzed via SOS commands
  (`dumpheap -stat`).
- **dotnet-gcdump**: Triggers Gen 2 GC and captures lightweight (~30MB)
  EventPipe streams of survived objects. Safe for production.
- **Workflow**:
  1. `dotnet-gcdump collect -p <PID> -o before.gcdump`
  2. Apply load.
  3. `dotnet-gcdump collect -p <PID> -o after.gcdump`
  4. Compare in Visual Studio or PerfView to find top generic types contributing
     to retained object graphs.

## Refactoring Strategies and Optimizations

1. **LOH Avoidance via ArrayPool**: Arrays on LOH are rarely compacted, leading
   to fragmentation. Refactor large arrays (HTTP buffers, streams) to use
   `System.Buffers.ArrayPool<T>`. Rent buffers and return them post-operation.
2. **Value Types (struct)**: Refactor short-lived, high-frequency data transfer
   objects from `class` (reference types) to `struct` (value types).
   Stack-allocated data bypasses managed heap and GC entirely.
3. **GC Configuration**: Use `DOTNET_GCHighMemPercent` in high-memory
   environments to enforce full GC collections.
