# Python Memory Profiling & Optimization

Python employs reference counting combined with a secondary cyclic garbage
collector. Its abstraction layer, PyMalloc, optimizes small objects but
obfuscates consumption—especially in C-extensions like NumPy/Pandas.

## Profiling Tools & Diagnostic Workflows

### Tracemalloc & Continuous Daemons

- **Workflow**: Tracks interpreter allocations (file and line numbers).
- **Production Strategy**: Embed a background daemon thread that calls
  `tracemalloc.start()`, continuously evaluates memory vs a threshold, and logs
  the top 10 leaking locations using `snapshot.compare_to(previous_snapshot)`
  when triggered.

### Memray & Native Flame Graphs

- **Workflow**: High-resolution continuous tracking across Python and native
  C/C++ extensions.
- **Command**: `python3 -m memray run --native my_script.py` (The `--native`
  flag exposes C/C++ allocations inside compiled modules).
- **Analysis**: Generate HTML flame graphs via
  `memray flamegraph --leaks <output-file>` to visualize absolute depths and
  byte sizes.

## Refactoring Strategies and Optimizations

1. **Structural Memory Reduction (`__slots__`)**: Python objects use `__dict__`
   hash tables by default (massive overhead). Implement
   `__slots__ = ('attr1', 'attr2')` to use fixed-size arrays instead. Reduces
   memory by 40-60%.
2. **Generators & Deferred Evaluation**: Prevent OOMs when processing gigabyte
   datasets by replacing list comprehensions (`[x for x in data]`) with
   generator expressions (`(x for x in data)`). Process items lazily.
3. **String Interning**: For repetitive datasets, use `sys.intern(string_val)`
   to retain a single global instance replaced by efficient pointer references.
4. **Vectorization (NumPy)**: Refactor heavy math over large datasets into NumPy
   arrays, which bypass Python overhead by utilizing contiguous C-style memory
   blocks (SoA logic).
