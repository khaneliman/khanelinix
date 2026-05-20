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
- Prefer `let` plus standard attrsets over `rec { ... }` when possible.
- If using IFD, consider materializing outputs into repo files to avoid
  evaluator-builder context switches.
- Avoid repeated imports of Nixpkgs, Home Manager, or flake inputs inside
  per-host or per-user maps.
- Avoid `builtins.readDir` over large trees during module import; materialize
  file lists or narrow the directory.
- Avoid generating many options with dynamic names unless the module API
  genuinely needs them; option declaration and merge cost scales with surface
  area.

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
- `flake-parts` or module helpers are not automatically the problem; profile
  before replacing structure.

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
