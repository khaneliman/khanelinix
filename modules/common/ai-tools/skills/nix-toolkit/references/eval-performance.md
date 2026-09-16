# Evaluation Performance

Use this reference to measure evaluation cost and decide whether an optimization
is worthwhile. [Performance-aware patterns](performance-patterns.md) owns
construct selection and semantic checks; this reference owns experimental
controls, profiling, and acceptance evidence.

## 1. Benchmarking and Baselining

```bash
<path-to-skill>/scripts/eval-benchmark.sh --runs 10 --warmup 3 \
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

- Documentation generation: profile its contribution. Disabling it with
  `documentation.enable = false;` is a feature reduction requiring an explicit
  user decision, not a behavior-preserving optimization.
- `home-manager.useGlobalPkgs = true;`: investigate sharing package sets only
  when Home Manager's package configuration and overlays can be preserved.
- `inputs.<name>.follows = "nixpkgs";`: reduces dependency graph; validate
  cache-hit tradeoffs.

### Select A Candidate From The Profile

| Observed work                                       | Authoring reference                                                                                                                                  |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Repeated item-independent computation               | [Sharing work](performance-patterns.md#sharing-work)                                                                                                 |
| Accumulator thunks or list construction             | [Folds and recursion](performance-patterns.md#folds-and-recursion)                                                                                   |
| Growing attrset merges                              | [Attribute-set composition](performance-patterns.md#attribute-set-composition)                                                                       |
| Broad source copying                                | [Local paths](performance-patterns.md#local-paths-in-strings)                                                                                        |
| String processing or path lookup                    | [String manipulation](performance-patterns.md#string-manipulation) and [attribute names](performance-patterns.md#attribute-names-over-built-strings) |
| Import discovery or repeated package-set evaluation | [Module import boundaries](performance-patterns.md#module-import-boundaries)                                                                         |

Run the selected pattern's semantic checks before benchmarking it. Force the
same consumed output in both measurements; unused-expression timings do not
establish improvement in the caller's workload.

## 3a. Suspicious Hotspots

- Documentation/manual generation dominates NixOS eval.
- Nixvim and plugin-heavy modules create large option graphs.
- HM without `useGlobalPkgs` evaluates Nixpkgs twice.
- Overlays that import Nixpkgs internally multiply evaluation cost. A single
  overlay does NOT re-evaluate all of Nixpkgs. Only overridden attributes
  re-evaluate.
- `specialisations` and NixOS `containers` are highest-cost: each
  duplicates/re-evaluates the config graph (N×M multiplier). Prefer lighter
  isolation when full graph duplication isn't required.
- `flake-parts` or module helpers are not automatically the problem; profile
  first.

## 3b. Environmental Factors

- Record source selection and working-tree state for both measurements. Git
  flakes and path inputs select files differently; source copying can confound
  timing. Use isolated snapshots when needed; do not stash unrelated work.
- `nix eval`/`nix-instantiate` is single-threaded. For many independent
  installables, use `nix-eval-jobs` with `--max-memory-size` (workers each load
  the full Nixpkgs graph; memory scales linearly with worker count) and
  `--check-cache-status`.

## 4. Verification

```bash
hyperfine --warmup 3 --runs 10 \
  "nix eval --raw \".#nixosConfigurations.${host}.config.system.build.toplevel.drvPath\" --option eval-cache false"
```

Accept changes only after semantic checks pass and measured benefits justify
complexity against the task target. Report timing mean, variance, and percentage
change; report memory regressions even when time improves. Fewer thunks alone do
not prove a user-visible speedup.

## Readability And Feature Tradeoffs

Accept localized complexity when measured benefits meet the task's performance
target. Explain the readability cost and why the simpler form is insufficient.
There is no universal percentage threshold. Retain the clearer form when
measurements are inconclusive.

Keep feature reductions separate from behavior-preserving changes. Disabling
documentation or removing needed modules and packages sacrifices capabilities;
present the lost capability, measured benefit, and explicit user decision
needed. Keep behavior unchanged until that tradeoff is accepted. Shared package
sets and input `follows` also require checking configuration, overlays, and
versions.

## Rules

- Always include `--option eval-cache false` in performance tests.
- Never claim a speedup without before/after multi-run benchmark output.
- A change argued for on performance grounds needs a `hyperfine` baseline before
  it is proposed. Choosing a construct for clarity, correctness, or semantics
  does not; [Performance-aware patterns](performance-patterns.md) owns that
  selection and explicitly does not establish speedups.
- Prioritize measured hotspots. Keep feature reductions separate from equivalent
  changes; obtain an explicit user decision before sacrificing capabilities.
