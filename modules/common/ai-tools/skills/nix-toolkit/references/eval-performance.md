# Evaluation Performance

For review thresholds, semantic checks, and readability tradeoffs, read
[Review scenarios](review-scenarios.md). Optimization patterns below are
hypotheses until measured against the caller's performance target.

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

- Documentation generation: profile its contribution. Disabling it with
  `documentation.enable = false;` is a feature reduction requiring an explicit
  user decision, not a behavior-preserving optimization.
- `home-manager.useGlobalPkgs = true;`: investigate sharing package sets only
  when Home Manager's package configuration and overlays can be preserved.
- `inputs.<name>.follows = "nixpkgs";`: reduces dependency graph; validate
  cache-hit tradeoffs.

### Nix Language Patterns

- Measure sharing repeated, item-independent work outside maps. Keep bindings at
  their narrowest useful shared scope and preserve lazy error behavior.
- Choose `let` versus `rec` for scope clarity. Neither syntax alone proves an
  evaluation improvement.
- Use strict `builtins.foldl'` / `lib.foldl'` when the accumulator must be
  evaluated. Preserve intentional laziness and check error behavior.
- For transitive-closure traversals, use `builtins.genericClosure`: runs in C++,
  deduplicates in place, bypasses Nix recursion limit.
- Avoid heavy string manipulation; repeated split/concat degrades toward O(N^2).
  Use `builtins.fromJSON`/`fromTOML`; tokenize with `builtins.match` and reduce
  with strict `foldl'`.
- Avoid accidental broad-directory string coercion (`"${./.}"`). Keep path
  values or filter with `lib.fileset` when appropriate; preserve intentional
  store references and required source contents.
- Profile import-time work. Keep imports independent of final `config`; enable
  options can gate definitions, not config-dependent import discovery.
- Avoid `builtins.readDir` over large trees during module import; materialize
  file lists or narrow the directory.
- Avoid generating many options with dynamic names: option declaration/merge
  cost scales with surface area.
- Measure strict reductions only where the consumer needs them. Forcing unused
  dataset fields may increase work or expose previously unused errors.
- Use attribute-path helpers for lists of path components. Preserve missing-key
  behavior; do not infer performance from string construction alone.

### Attribute-Set Merge Candidates

| Operation                  | Candidate                 | Semantic constraint                                                       |
| -------------------------- | ------------------------- | ------------------------------------------------------------------------- |
| Small fixed shallow update | `a // b // c`             | Rightmost value wins; leave readable chains alone.                        |
| Large shallow update list  | `lib.mergeAttrsList list` | Preserve order and shallow collisions; compare against the existing fold. |
| Nested updates             | `lib.recursiveUpdate`     | Preserve recursive semantics; shallow merging is not equivalent.          |
| Module definitions         | `lib.mkMerge`             | Preserve option types, priorities, and conditional definitions.           |

Growing-accumulator merges can repeatedly copy keys. Inspect the pinned
[Nixpkgs implementation](https://github.com/NixOS/nixpkgs/blob/master/lib/attrsets.nix)
and profile representative inputs rather than applying a universal complexity
threshold. `zipAttrsWith` groups values by key; it does not choose the caller's
merge policy.

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

## Constitutional Rules

- Never propose an optimization without a `hyperfine` baseline command.
- Always include `--option eval-cache false` in performance tests.
- Never claim a speedup without before/after multi-run benchmark output.
- Prioritize measured hotspots. Keep feature reductions separate from equivalent
  changes; obtain an explicit user decision before sacrificing capabilities.
