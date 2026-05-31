# Evaluation Performance

Use this playbook to benchmark, profile, and optimize Nix evaluation performance
for NixOS, Home Manager, and Nixvim configurations.

## 1. Benchmarking and Baselining

Before changing anything, establish a statistically meaningful baseline.

Use the bundled script for repeatable local eval benchmarks:

```bash
scripts/eval-benchmark.sh --runs 10 --warmup 3 \
  nix eval --raw .#nixosConfigurations.host.config.system.build.toplevel.drvPath
```

The script appends `--option eval-cache false`, uses `hyperfine`, and captures a
single-run `NIX_SHOW_STATS` summary after timing.

### Tools

- `hyperfine` for wall-clock timing
- `NIX_SHOW_STATS` for evaluator internals such as thunks and memory

### Execution Rules

- Disable eval cache for performance tests: always pass
  `--option eval-cache false`.
- Use at least 3 warmup runs in `hyperfine`.
- Compare performance using multiple measured runs only, minimum 10 runs per
  variant. Never use single-run timings for decisions.

### Baseline Command Template

```bash
config_path="./configuration.nix"

hyperfine --warmup 3 --runs 10 \
  "nix-instantiate --eval --option eval-cache false \"$config_path\""
```

### Metric Extraction

```bash
host="host-name"

NIX_SHOW_STATS=1 NIX_SHOW_STATS_PATH=stats.json \
  nix eval ".#nixosConfigurations.${host}.config.system.build.toplevel" \
  --option eval-cache false

jq '.nrThunks, .gc.totalBytes' stats.json
```

For Home Manager configurations:

```bash
home_attr="user@host"

NIX_SHOW_STATS=1 NIX_SHOW_STATS_PATH=hm-stats.json \
  nix eval ".#homeConfigurations.${home_attr}.activationPackage.drvPath" \
  --option eval-cache false
```

## 2. Profiling

If evaluation is slow, identify where evaluator time is spent with the built-in
stack sampler.

```bash
config_path="./configuration.nix"
attr="system"

nix-instantiate --eval-profiler flamegraph "$config_path" -A "$attr"
```

Generate the flamegraph:

```bash
flamegraph.pl nix.profile > profile.svg
```

Analysis rules:

- Wide bars usually indicate functions/files consuming the most total time.
- Deep stacks can indicate recursion or expensive module merging.

### Proving Algorithmic Degradation

The flamegraph samples by time (default 99 Hz), so cheap-but-frequent calls can
hide. To count exact function invocations instead of sampling time, set the
frequency to 0:

```bash
nix-instantiate --eval-profiler flamegraph --eval-profiler-frequency 0 \
  "$config_path" -A "$attr"
```

This samples after every call, so it is slow, but it exposes the true call count
of recursive merges (`binaryMerge`, `recursiveUpdate`) and instantly reveals
whether a naive fold has produced an O(N^2) call graph. Use it to confirm a
merge hotspot before refactoring, not for routine timing.

## 2a. Separate Eval From Build

Use drvPath evaluation when you only want evaluator cost:

```bash
host="host-name"

nix eval --raw ".#nixosConfigurations.${host}.config.system.build.toplevel.drvPath" \
  --option eval-cache false
```

Do not use `nix build` timings as eval-performance evidence unless the build is
already fully substituted or separately controlled.

## 3. Proven Optimization Patterns

Apply these in order based on profiling output.

### System-Level

- Disable docs when possible: `documentation.enable = false;`
  - Often a top cause of slow NixOS evaluation due to manual generation.
- In Home Manager, prefer global pkgs: `home-manager.useGlobalPkgs = true;`
  - Prevents redundant second evaluation of Nixpkgs.
- Make flake inputs follow root nixpkgs where safe:
  - `inputs.<name>.follows = "nixpkgs";`
  - Reduces dependency graph size, but validate cache-hit tradeoffs.

### Nix Language Patterns

- Reduce thunk creation by moving repeated `let` bindings outside loops/maps.
- Prefer `let` plus standard attrsets over `rec { ... }` when possible. `rec`
  resolves interdependent references via fixpoint iteration; binding shared
  values in a `let` before the set avoids that work.
- Use strict `builtins.foldl'` / `lib.foldl'` (not `foldl` or hand-written
  recursion) for list reductions. The strict accumulator avoids a thunk chain
  that pressures the GC and can overflow the evaluation stack.
- For transitive-closure traversals (dependency graphs, reachability), use the
  `builtins.genericClosure` primop instead of manual recursion; it runs in C++,
  dedups in place, and bypasses the Nix recursion limit.
- Avoid heavy string manipulation. Repeated split/concat over large strings
  degrades toward O(N^2). Read structured data with `builtins.fromJSON` /
  `fromTOML`; if parsing is unavoidable, tokenize with `builtins.match` and
  reduce with a strict `foldl'`.
- Do not interpolate local paths into strings (`"${./.}"`). Coercing a path to a
  string copies the target into the store before the string resolves, so a
  monorepo root triggers a full-tree copy on every eval. Keep path values as
  paths, or select sources with `lib.fileset` before they reach the store. This
  is the authoring-time analogue of the dirty-working-tree copy in section 3b.
- Remember that importing a NixOS/HM module evaluates it; eval time scales
  linearly with the import count. Gate optional/expensive modules behind enable
  options and keep transient configs to a minimal import baseline.
- If using IFD, consider materializing outputs into repo files to avoid
  evaluator-builder context switches.
- Avoid repeated imports of Nixpkgs, Home Manager, or flake inputs inside
  per-host or per-user maps.
- Avoid `builtins.readDir` over large trees during module import; materialize
  file lists or narrow the directory.
- Avoid generating many options with dynamic names unless the module API
  genuinely needs them; option declaration and merge cost scales with surface
  area.
- Force strict evaluation of large static datasets (bulk lists, prompt text,
  port/IP tables) instead of wrapping them in deeply nested lazy `map`/`filter`
  chains; needless thunk allocation pressures the GC without saving work that is
  always demanded anyway.
- Prefer attribute-path lookups (`hasAttrByPath`, `attrByPath`,
  `getAttrFromPath`) over dynamically concatenating strings and comparing them.
  Static, interned attribute names compare by pointer; dynamically built strings
  fall back to character-by-character comparison in the evaluator's symbol
  table.

### Attribute-Set Merge Complexity

Attribute sets are immutable, so each `//` allocates a new set and copies the
merged keys. The way many sets are combined dominates cost as the count grows.

| Strategy         | Syntax                             | Time / space | Use when                          |
| ---------------- | ---------------------------------- | ------------ | --------------------------------- |
| Sequential chain | `a // b // c`                      | O(N·m)       | small, static, hardcoded (N < ~5) |
| Linear fold      | `foldl' (a: b: a // b) {} list`    | O(N^2·m)     | avoid for dynamic lists           |
| Binary merge     | `lib.attrsets.mergeAttrsList list` | O(N·m·log N) | dynamic/large lists, overlays     |

- A `foldl'`/`foldr` of `//` over a list grows a single accumulator, re-copying
  all prior keys on every step — quadratic. For dynamically sized lists, large
  package sets, or generated attr arrays, use `lib.attrsets.mergeAttrsList`
  (balanced binary merge) instead.
- For surface-level grouping by key across a list, prefer
  `lib.attrsets.zipAttrsWith`.
- The same quadratic trap applies to `foldl' lib.recursiveUpdate {} list`. For
  recursive merges of many sets, fold over a binary-merged structure rather than
  a linear accumulator, or restructure so deep recursive merging is not needed.
- Keep `mergeAttrsList` for genuinely dynamic or large inputs; for a trivial
  fixed merge the plain `a // b // c` chain has lower constant overhead than the
  recursive helper.

### Tuning Experiments

Test one hypothesis at a time:

- Toggle `documentation.enable = false;` only long enough to measure whether
  docs dominate evaluation.
- Compare Home Manager with and without `home-manager.useGlobalPkgs = true;`.
- Compare input graph changes before broad `follows` edits.
- Temporarily bypass suspected dynamic imports or large `readDir` scans, then
  restore structure if the benchmark does not move.

Do not keep exploratory Nix edits unless the measured result justifies them.

## 3a. Suspicious Hotspots

- Documentation/manual generation can dominate NixOS evaluation.
- Nixvim and plugin-heavy modules can create large option graphs.
- Home Manager without global pkgs can evaluate Nixpkgs twice.
- Overlays that import Nixpkgs internally often multiply evaluation cost.
- A single overlay does **not** re-evaluate all of Nixpkgs; only the overridden
  attributes re-evaluate, and unchanged values stay structurally shared. Suspect
  overlays only when they import Nixpkgs internally or override deep nested
  attributes (which discards the shared pointers).
- `specialisations` and NixOS `containers` are the highest-cost structural
  feature: each duplicates and re-evaluates the configuration graph, so N
  evaluations across M specialisations/containers is an N×M multiplier. Budget
  them deliberately and prefer lighter isolation (systemd dynamic users, plain
  wrappers) when full graph duplication is not required.
- `flake-parts` or module helpers are not automatically the problem; profile
  before replacing structure.

## 3b. Environmental Factors That Mask Eval Cost

- A dirty (uncommitted) git working tree forces Nix to copy the whole working
  directory into the store before evaluating a flake, adding disk I/O latency
  that masks the real eval time. Commit or stash before benchmarking, or compare
  only clean-tree runs.
- Single-threaded `nix eval`/`nix-instantiate` bounds large multi-package
  evaluations to one core. For evaluating many independent installables (CI,
  bulk package checks), `nix-eval-jobs` spawns parallel workers; cap each with
  `--max-memory-size` (workers each load the full Nixpkgs graph, so memory
  scales linearly with worker count) and use `--check-cache-status` / caching to
  avoid redundant re-evaluation.

## 4. Verification

After each optimization, rerun the baseline benchmark with the same command
shape:

```bash
host="host-name"

hyperfine --warmup 3 --runs 10 \
  "nix eval --raw \".#nixosConfigurations.${host}.config.system.build.toplevel.drvPath\" --option eval-cache false"
```

Accept only changes that improve:

- `Mean [s]` wall-clock time, and/or
- `nrThunks` or memory metrics.

Report percentage improvement from multi-run results, including mean and
variance, not from single executions.

## Constitutional Rules

- Never propose an optimization without first providing a `hyperfine` baseline
  command.
- Always include `--option eval-cache false` in performance tests.
- Never claim a speedup unless it is demonstrated by before/after multi-run
  benchmark output.
- Prefer structural changes such as `useGlobalPkgs`, docs toggles, and input
  graph simplification before micro-optimizations unless profiling points to
  language-level hotspots.
