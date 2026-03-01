# TypeScript / Node.js Memory Profiling & Optimization

Node.js leverages Google's V8 engine with a generational garbage collector.
Memory leaks usually stem from references retained unintentionally in global
scopes, closures, or lingering event listeners.

## Profiling Tools & Diagnostic Workflows

### V8 Inspector & Differential Heap Snapshots

- **Workflow**: Launch with `node --inspect`. Connect via `chrome://inspect` and
  open the Memory tab.
- **Differential Analysis**:
  1. Let application warm up. Capture baseline snapshot.
  2. Apply load on suspected leaking functionality. Let settle.
  3. Capture a second snapshot. Compare via "Comparison" mode for positive
     deltas.
- **Production Safety**: Taking snapshots halts the main thread. Use
  `--heapsnapshot-signal=SIGUSR2` and the native `v8` module for programmatic
  snapshots.

### Clinic.js Heap Profiler

- **Workflow**: Automated continuous allocation tracking generating flame
  graphs.
- **Command**:
  `clinic heapprofiler --autocannon [ /api/endpoint -d 120 ] -- node server.js`.
- **Benefit**: Displays a visual flame graph identifying exactly which function
  and its descendants allocate the most transient memory under load.

## Refactoring Strategies and Optimizations

Minimize garbage collection (GC) churn to prevent event loop blocks.

1. **Object Pooling**: Avoid continuous instantiation in hot loops. Keep
   pre-allocated arrays of objects. Reset properties and return object to pool
   when done.
2. **Mitigate Dynamic Strings**: Refrain from dynamic concatenation for property
   lookups. Avoid excessive `split` or heavy regex allocations; refactor using
   Map objects with stable keys.
3. **Closure Scope Refactoring**: Inner functions capture parent scope. Extract
   them to higher, isolated scopes so they do not unintentionally retain large
   temporary datasets from the parent scope, allowing GC sweeps.
