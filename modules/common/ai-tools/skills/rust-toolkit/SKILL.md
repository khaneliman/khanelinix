---
name: rust-toolkit
description: Rust architecture and engineering playbooks for Cargo crates and workspaces. Use when creating, restructuring, reviewing, debugging, optimizing, migrating, or testing Rust libraries, services, CLIs, Cargo.toml/workspaces, editions and toolchains, stable or nightly experiments, unsafe or concurrent code, ownership-driven state machines, module and crate boundaries, API and error design, typestate, validation, build/runtime profiling, SIMD, PGO, or allocator decisions. Use bevy-toolkit for engine-specific Bevy work.
---

# Rust Toolkit

Route Rust engineering work through repository evidence, then load only the
reference needed for the current decision.

## Start Here

1. Read contributor instructions and existing manifests, toolchain files, CI,
   features, and validation commands before proposing structure.
2. Run `scripts/project-context.py <path>` for a bounded first-pass inventory.
   Read [scripts.md](references/scripts.md) for behavior and limitations.
3. Preserve the repository's MSRV, edition, feature matrix, target platforms,
   and public API policy unless the user requests change.
4. Pick one primary mode below. Load another reference only when work crosses
   that boundary.

## Routing

1. **project architecture** — crate/module/workspace boundaries, dependency
   direction, visibility, errors, features, and project initialization. Read
   [architecture.md](references/architecture.md).
2. **type-driven design** — typestate, runtime state machines, builders,
   newtypes, trait dispatch, ownership, and concurrency boundaries. Read
   [type-driven-design.md](references/type-driven-design.md).
3. **correctness and testing** — test placement, property/model testing, unsafe
   review, Miri, Loom, fuzzing, sanitizers, and validation ladders. Read
   [correctness-and-testing.md](references/correctness-and-testing.md).
4. **performance** — compile-time and runtime measurement, data layout,
   allocations, SIMD, custom allocators, PGO, profiles, linkers, and caching.
   Read [performance.md](references/performance.md).
5. **toolchain evolution** — edition or MSRV migrations, release and target
   changes, unstable language/Cargo features, and nightly experiments. Read
   [toolchain-evolution.md](references/toolchain-evolution.md).
6. **repeatable checks** — use the inventory and quality-gate helpers. Read
   [scripts.md](references/scripts.md).

## Core Rules

- Make the smallest boundary that enforces a real invariant. Do not split a
  crate, add a trait, or encode typestate only for visual symmetry.
- Measure before changing profiles, linkers, codegen backends, data layout, or
  allocators. Report baseline, changed variable, and comparable result.
- Derive version-sensitive APIs from manifests and matching official docs. Never
  silently rewrite code to the newest Rust release.
- Treat RFCs, project goals, tracking issues, and accepted nightly syntax as
  research leads, not proof that a feature is stable.
- Prefer repository-native checks. Use `scripts/rust-verify.sh` only when its
  command shape matches project policy.

## Cross-Skill Boundaries

- Use `memory-profiler` for leak, OOM, fragmentation, or heap-profile work.
- Use `bevy-toolkit` for Bevy ECS, plugins, lifecycle, MCP/BRP, runtime control,
  rendering, and visual validation.
- Use `security-toolkit` for explicit security audits or threat models.
- Use `nix-toolkit` or `writing-nix` for Nix environment changes.
- Use `git-toolkit` for commit structure and history operations.
