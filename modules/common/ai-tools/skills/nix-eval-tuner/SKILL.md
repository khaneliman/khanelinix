---
name: nix-eval-tuner
description: Profile, benchmark, and optimize Nix evaluation performance for NixOS, Home Manager, and Nixvim configurations. Use when users report slow nixos-rebuild times, slow Home Manager activation, or high memory usage during Nix evaluation.
---

# Nix Evaluation Tuning

Use this skill to benchmark, profile, and optimize Nix evaluation performance.

## 1. Benchmarking and Baselining

Before changing anything, establish a statistically meaningful baseline.

### Tools

- `hyperfine` for wall-clock timing
- `NIX_SHOW_STATS` for evaluator internals (thunks, memory)

### Execution Rules

- Disable eval cache for performance tests: always pass
  `--option eval-cache false`.
- Use at least 3 warmup runs in `hyperfine`.
- Compare performance using multiple measured runs only (minimum 10 runs per
  variant). Never use single-run timings for decisions.

### Baseline Command Template

```bash
hyperfine --warmup 3 --runs 10 \
  "nix-instantiate --eval --option eval-cache false <path-to-config>"
```

### Metric Extraction

```bash
NIX_SHOW_STATS=1 NIX_SHOW_STATS_PATH=stats.json \
  nix eval .#nixosConfigurations.<name>.config.system.build.toplevel \
  --option eval-cache false

jq '.nrThunks, .gc.totalBytes' stats.json
```

## 2. Profiling (Hotspot Identification)

If evaluation is slow, identify where evaluator time is spent with the built-in
stack sampler.

### Generate Profile

```bash
nix-instantiate --eval-profiler flamegraph "<path-to-config>" -A <attr>
```

### Generate Flamegraph

Requires `flamegraph.pl` (from the `flamegraph` package).

```bash
flamegraph.pl nix.profile > profile.svg
```

### Analyze Profile

- Wide bars: find functions/files consuming the most total time.
- Deep stacks: look for deep recursion or expensive module merging.

## 3. Proven Optimization Patterns

Apply these in order based on profiling output.

### System-Level (NixOS and Home Manager)

- Disable docs when possible: `documentation.enable = false;`
  - Often the top cause of slow NixOS evaluation due to manual generation.
- In Home Manager, prefer global pkgs: `home-manager.useGlobalPkgs = true;`
  - Prevents redundant second evaluation of Nixpkgs.
- Make flake inputs follow root nixpkgs where safe:
  - `inputs.<name>.follows = "nixpkgs";`
  - Reduces dependency graph size, but validate cache-hit tradeoffs.

### Nix Language Patterns

- Reduce thunk creation by moving `let` bindings outside loops/maps.
- Prefer `let` + standard attrsets over `rec { ... }` when possible.
- If using IFD, consider materializing outputs into repo files to avoid
  evaluator-builder context switches.

## 4. Verification

After each optimization, rerun baseline benchmarks.

Use the same command shape for before/after and compare distributions from
multiple runs:

```bash
hyperfine --warmup 3 --runs 10 \
  "nix eval --raw .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath --option eval-cache false"
```

Accept only changes that improve:

- `Mean [s]` (wall-clock), and/or
- `nrThunks` / memory metrics

Report percentage improvement from multi-run results (mean and variance), not
from single executions.

## Constitutional Rules

- Never propose an optimization without first providing a `hyperfine` baseline
  command.
- Always include `--option eval-cache false` in performance tests.
- Never claim a speedup unless it is demonstrated by before/after multi-run
  benchmark output.
- Prefer structural changes (`useGlobalPkgs`, docs toggles, input graph
  simplification) before micro-optimizations unless profiling points to
  language-level hotspots.
