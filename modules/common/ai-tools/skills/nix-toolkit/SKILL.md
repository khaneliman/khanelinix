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
7. **ifd-remediation** — detect, diagnose, and refactor Import From Derivation
   (IFD) bottlenecks.
8. **nix-authoring** — delegate to `writing-nix`; stop reading this skill unless
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
- Read [ifd-remediation.md](references/ifd-remediation.md) for Import From
  Derivation (IFD) diagnostics, error signatures, ecosystem overrides, and
  refactoring protocols.

## Scripts

Read [scripts.md](references/scripts.md) when a first-pass report or repeatable
measurement can replace manual command assembly.

## Cross-Skill Boundaries

Read [operating-rules.md](references/operating-rules.md) for cross-skill
boundaries, reporting rules, and skill maintenance.

## Reporting Rules

Show exact commands, separate facts from hypotheses, and label snippets as
executed, dry-run checked, syntax checked, or template only.
