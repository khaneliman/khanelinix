# C++ Memory Profiling & Optimization

In C and C++, developers have absolute responsibility for memory management. The
lack of runtime safety checks makes memory leaks, double frees, and heap
corruption serious risks.

## Profiling Tools & Diagnostic Workflows

### Valgrind (Memcheck)

- **Use Case**: Deep bounds checking, use-after-free, uninitialized values,
  exact leak line numbers.
- **Overhead**: Extreme (20x-30x slowdown); synthetic CPU.
- **Command**: `valgrind --leak-check=yes ./executable <args>`
- **Workflow**: Compile with `-g` (debugging symbols) and restrict optimization
  to `-O0` or `-O1`.

### Heaptrack

- **Use Case**: Heap profiling, identifying allocation hotspots, isolating
  temporary allocations.
- **Overhead**: Low to Moderate; native tracing.
- **Command**: `heaptrack ./executable` or attach via `heaptrack -p <PID>`.
- **Analysis**: Use `heaptrack_gui` or `heaptrack_print` on the generated
  `heaptrack.<executable>.<PID>.gz` file.

## Refactoring Strategies and Optimizations

1. **Custom Memory Pools and Arena Allocators**: Refactor hot paths to use
   custom memory pools to avoid OS allocator latency and fragmentation.
   - Request large contiguous memory blocks from the system and divide
     internally into fixed-size chunks.
   - Use a C++ union combining `std::aligned_storage` and a free-list pointer.
   - Reclaiming object memory pushes the chunk back to the pool's free list
     instead of returning to the OS, turning system calls into O(1) pointer
     assignments.

2. **Small Object and Small String Optimization (SSO)**:
   - For string operations, utilize standard library SSO. If a string is under
     architecture limits (typically 15-22 chars), it remains entirely on the
     stack.
   - Bypasses the heap and guarantees perfect cache locality.
