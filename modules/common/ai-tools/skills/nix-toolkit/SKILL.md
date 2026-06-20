---
name: nix-toolkit
description: Nix operational playbooks for package diffs, build debugging, closure analysis, dependency forensics, flake maintenance, and evaluation performance tuning. Use when comparing Nix build outputs, diagnosing derivation failures, finding unexpected runtime/build dependencies, inspecting closure size, maintaining flakes, or profiling slow NixOS/Home Manager/Nixvim evaluation.
---

# Nix Toolkit

Router for Nix operational/debugging workflows. For writing or refactoring Nix
modules, expressions, overlays, packages, or flake outputs, use `writing-nix`.

Route to one mode; load only that reference:

1. **package-diffing** — [package-diffing.md](references/package-diffing.md)
2. **build-debugging** — [build-debugging.md](references/build-debugging.md)
3. **closure-analysis** — [closure-analysis.md](references/closure-analysis.md)
4. **dependency-forensics** —
   [dependency-forensics.md](references/dependency-forensics.md)
5. **flake-maintenance** —
   [flake-maintenance.md](references/flake-maintenance.md)
6. **eval-performance** — [eval-performance.md](references/eval-performance.md)
7. **ifd-remediation** — [ifd-remediation.md](references/ifd-remediation.md)
8. **nix-authoring** — delegate to `writing-nix`

If intent is unclear, ask before proceeding.

Read [scripts.md](references/scripts.md) when a first-pass report or repeatable
measurement can replace manual command assembly.

See [operating-rules.md](references/operating-rules.md) for cross-skill routing
and reporting rules.
