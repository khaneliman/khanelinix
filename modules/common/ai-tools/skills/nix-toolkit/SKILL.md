---
name: nix-toolkit
description: Nix operational playbooks for package diffs, build debugging, closure analysis, dependency forensics, flake maintenance, and evaluation performance tuning. Use when comparing Nix build outputs, diagnosing derivation failures, finding unexpected runtime/build dependencies, inspecting closure size, maintaining flakes, or profiling slow NixOS/Home Manager/Nixvim evaluation.
---

# Nix Toolkit

Use this skill as the base router for Nix workflows that are about operating,
debugging, comparing, or tuning Nix systems and packages. For writing or
refactoring Nix modules, expressions, overlays, packages, or flake outputs, use
`writing-nix` first.

## How I choose what to do (progressive disclosure)

When invoked, route to one mode:

1. **package-diffing** — compare local package outputs against another branch,
   fork, or nixpkgs revision with `diffoscope`, file lists, and closure checks.
2. **build-debugging** — inspect failed builds, logs, derivations, and store
   outputs.
3. **closure-analysis** — inspect dependency and size drift with `nix path-info`
   and related tools.
4. **dependency-forensics** — find why a dependency is present, whether it is a
   runtime reference or build-time edge, and where store paths are embedded.
5. **flake-maintenance** — update, inspect, and validate flake inputs/locks.
6. **eval-performance** — benchmark, profile, and optimize Nix evaluation
   performance.
7. **nix-authoring** — delegate to `writing-nix`; stop reading this skill unless
   operational debugging is also needed.

If intent is unclear, ask for the mode before applying changes.

## Playbooks

Load only the reference for the chosen mode unless the investigation crosses
mode boundaries.

- Read [package-diffing.md](references/package-diffing.md) for package output
  comparisons, including local vs remote branch `diffoscope` workflows,
  fixed-output comparisons, and normalized store-path diffs.
- Read [build-debugging.md](references/build-debugging.md) for failed build
  triage, log collection, derivation JSON inspection, sandbox recreation, and
  rebuild loops.
- Read [closure-analysis.md](references/closure-analysis.md) for closure size
  and dependency drift analysis, including `diff-closures` and
  `why-depends --derivation`.
- Read [dependency-forensics.md](references/dependency-forensics.md) for
  unexpected runtime/build dependencies, multi-output confusion, and embedded
  store path searches.
- Read [flake-maintenance.md](references/flake-maintenance.md) for flake lock,
  input graph, stale input, and cache/substitution checks.
- Read [eval-performance.md](references/eval-performance.md) for slow eval,
  `hyperfine`, `NIX_SHOW_STATS`, and eval profiler workflows.

## Scripts

Use scripts for first-pass reports and repeatable measurements; use references
when diagnosis, interpretation, or custom command shaping is needed.

- `scripts/closure-diff-report.sh <before> <after>`: build two installables
  without linking and report closure drift.
- `scripts/dependency-trace.sh <target> [dependency]`: inspect direct
  references, recursive closure, and optional `why-depends` paths.
- `scripts/package-option-scan.sh <package-list-installable> [pattern]`: inspect
  package-list options without building the package or system closure.
- `scripts/drv-graph-grep.sh [--allow-meta] <derivation> <pattern>`: instantiate
  a derivation graph and search drv names without realizing outputs.
- `scripts/eval-benchmark.sh [--runs N] [--warmup N] <eval command...>`:
  benchmark eval commands and capture `NIX_SHOW_STATS`.

## Cross-Skill Boundaries

- Use `writing-nix` before editing Nix code or module structure.
- Use `git-toolkit` for history surgery, commit strategy, and branch hygiene.
- Use `github-toolkit` for GitHub issues, PR review comments, and CI checks.
- Prefer one-off tools through `nix shell`, `nix run`, `,`, or `nix-shell`
  instead of adding persistent dependencies only for investigation.

## Reporting Rules

- Show exact commands used or recommended.
- Separate measured facts from hypotheses.
- Label snippets as one of: executed, dry-run checked, syntax checked, or
  template only.
- For performance claims, require before/after measurements from the same
  command shape.
- For package diffs, report both the compared inputs and the comparison method.

## Skill Maintenance

Run `scripts/validate-snippets.sh` after editing references. It checks shell
fence syntax and verifies the Nix subcommands/flags used by the playbooks are
available in the current environment. It intentionally does not build packages,
fetch remote forks, or update lock files.
