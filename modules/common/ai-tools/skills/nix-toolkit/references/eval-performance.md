# Evaluation Performance

## 1. Benchmarking and Baselining

```bash
scripts/eval-benchmark.sh --runs 10 --warmup 3 \
  nix eval --raw .#nixosConfigurations.host.config.system.build.toplevel.drvPath
```

Appends `--option eval-cache false`, uses `hyperfine`, captures single-run
`NIX_SHOW_STATS` after timing.

Manual baseline:

```bash
config_path="./configuration.nix"

hyperfine --warmup 3 --runs 10 \
  "nix-instantiate --eval --option eval-cache false \"$config_path\""
```

Rules: always `--option eval-cache false`; minimum 3 warmups; minimum 10 runs;
never use single-run timings.

## Metric Extraction

```bash
host="host-name"

NIX_SHOW_STATS=1 NIX_SHOW_STATS_PATH=stats.json \
  nix eval ".#nixosConfigurations.${host}.config.system.build.toplevel" \
  --option eval-cache false

jq '.nrThunks, .gc.totalBytes' stats.json
```

Home Manager:

```bash
NIX_SHOW_STATS=1 NIX_SHOW_STATS_PATH=hm-stats.json \
  nix eval ".#homeConfigurations.${home_attr}.activationPackage.drvPath" \
  --option eval-cache false
```

## 2. Profiling

```bash
nix-instantiate --eval-profiler flamegraph "$config_path" -A "$attr"
flamegraph.pl nix.profile > profile.svg
```

Wide bars = most total time. Deep stacks = recursion or expensive module
merging.

Count exact invocations instead of sampling time (slow, reveals true call
count):

```bash
nix-instantiate --eval-profiler flamegraph --eval-profiler-frequency 0 \
  "$config_path" -A "$attr"
```

Use frequency 0 to confirm a merge hotspot (`binaryMerge`, `recursiveUpdate`
O(N^2) call graphs) before refactoring.

## 2a. Isolate Eval From Build

```bash
nix eval --raw ".#nixosConfigurations.${host}.config.system.build.toplevel.drvPath" \
  --option eval-cache false
```

Do not use `nix build` timings as eval evidence unless the build is fully
substituted.

## 3. Optimization Patterns

Apply in order based on profiling output.

### System-Level

- `documentation.enable = false;` — often top cause of slow NixOS eval (manual
  generation).
- `home-manager.useGlobalPkgs = true;` — prevents redundant second Nixpkgs
  evaluation.
- `inputs.<name>.follows = "nixpkgs";` — reduces dependency graph; validate
  cache-hit tradeoffs.

### Nix Language Patterns

- Move repeated `let` bindings outside loops/maps to reduce thunk creation.
- Prefer `let` + standard attrsets over `rec { ... }` — `rec` uses fixpoint
  iteration; shared values in `let` avoid that.
- Use strict `builtins.foldl'` / `lib.foldl'` for list reductions (not `foldl`
  or hand-written recursion) — avoids GC-pressuring thunk chain.
- For transitive-closure traversals, use `builtins.genericClosure` — runs in
  C++, deduplicates in place, bypasses Nix recursion limit.
- Avoid heavy string manipulation; repeated split/concat degrades toward O(N^2).
  Use `builtins.fromJSON`/`fromTOML`; tokenize with `builtins.match` and reduce
  with strict `foldl'`.
- Do NOT interpolate local paths into strings (`"${./.}"`) — coercing a path
  copies the target into the store before resolving; keeps path values as paths,
  or use `lib.fileset`.
- Gate optional/expensive modules behind enable options; eval time scales
  linearly with import count.
- Avoid `builtins.readDir` over large trees during module import; materialize
  file lists or narrow the directory.
- Avoid generating many options with dynamic names — option declaration/merge
  cost scales with surface area.
- Force strict evaluation of large static datasets instead of wrapping in deeply
  nested lazy `map`/`filter` chains.
- Prefer `hasAttrByPath`, `attrByPath`, `getAttrFromPath` over dynamically
  concatenated strings — static interned names compare by pointer; dynamic
  strings fall back to character comparison.

### Attribute-Set Merge Complexity

| Strategy         | Syntax                             | Time / space | Use when                          |
| ---------------- | ---------------------------------- | ------------ | --------------------------------- |
| Sequential chain | `a // b // c`                      | O(N·m)       | small, static, hardcoded (N < ~5) |
| Linear fold      | `foldl' (a: b: a // b) {} list`    | O(N^2·m)     | avoid for dynamic lists           |
| Binary merge     | `lib.attrsets.mergeAttrsList list` | O(N·m·log N) | dynamic/large lists, overlays     |

- `foldl`/`foldr` of `//` over a list re-copies all prior keys on every step —
  quadratic. Use `lib.attrsets.mergeAttrsList` for dynamic/large lists.
- `lib.attrsets.zipAttrsWith` for surface-level grouping by key.
- Same quadratic trap applies to `foldl' lib.recursiveUpdate {} list`.

## 3a. Suspicious Hotspots

- Documentation/manual generation dominates NixOS eval.
- Nixvim and plugin-heavy modules create large option graphs.
- HM without `useGlobalPkgs` evaluates Nixpkgs twice.
- Overlays that import Nixpkgs internally multiply evaluation cost. A single
  overlay does NOT re-evaluate all of Nixpkgs — only overridden attributes
  re-evaluate.
- `specialisations` and NixOS `containers` are highest-cost: each
  duplicates/re-evaluates the config graph (N×M multiplier). Prefer lighter
  isolation when full graph duplication isn't required.
- `flake-parts` or module helpers are not automatically the problem; profile
  first.

## 3b. Environmental Factors

- Dirty working tree → Nix copies entire working directory into the store before
  eval, masking real eval time. Commit or stash before benchmarking.
- `nix eval`/`nix-instantiate` is single-threaded. For many independent
  installables, use `nix-eval-jobs` with `--max-memory-size` (workers each load
  the full Nixpkgs graph; memory scales linearly with worker count) and
  `--check-cache-status`.

## 4. Verification

```bash
hyperfine --warmup 3 --runs 10 \
  "nix eval --raw \".#nixosConfigurations.${host}.config.system.build.toplevel.drvPath\" --option eval-cache false"
```

Accept only changes that improve `Mean [s]` and/or `nrThunks`/memory metrics.
Report percentage improvement with mean and variance.

## Constitutional Rules

- Never propose an optimization without a `hyperfine` baseline command.
- Always include `--option eval-cache false` in performance tests.
- Never claim a speedup without before/after multi-run benchmark output.
- Prefer structural changes (`useGlobalPkgs`, docs toggles, input graph
  simplification) before language micro-optimizations unless profiling points to
  hotspots.
