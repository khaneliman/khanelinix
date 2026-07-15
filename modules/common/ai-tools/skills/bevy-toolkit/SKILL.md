---
name: bevy-toolkit
description: Bevy application and game-engine playbooks for ECS architecture, plugins, states, schedules, lifecycle cleanup, assets/scenes, runtime diagnostics, visual verification, and live control through Bevy Remote Protocol (BRP) and bevy_brp_mcp. Use when creating, restructuring, debugging, profiling, testing, launching, inspecting, mutating, capturing, or automating Bevy apps and plugins, including MCP-driven entity/resource queries, screenshots, keyboard or mouse input, and deterministic game-control scripts.
---

# Bevy Toolkit

Route Bevy work by engine concern and live-runtime need. Keep general Rust,
Cargo, unsafe, and allocator decisions in `rust-toolkit`.

## Start Here

1. Read contributor instructions, `Cargo.toml`, `Cargo.lock`, enabled Bevy
   features, development-only plugins, and repository-native launch/check
   scripts.
2. Confirm locked Bevy version before using API examples or migration advice.
3. For live work, inspect existing process and BRP status before launching
   another game. Prefer MCP lifecycle tools; use `scripts/brp-control.py` for
   deterministic direct-BRP calls and repository automation.
4. Use `brp_type_guide` before constructing or mutating reflected component or
   resource values.
5. Pick one primary route below. Load another reference only when work crosses
   its boundary.

## Routing

1. **ECS and plugin architecture** — components/resources, query data shape,
   plugin ownership, relationships, scenes, and headless composition. Read
   [architecture.md](references/architecture.md).
2. **states and scheduling** — lifecycle setup/teardown, state-scoped entities,
   system sets, deferred commands, events/messages, and observers. Read
   [lifecycle-and-scheduling.md](references/lifecycle-and-scheduling.md).
3. **MCP and BRP** — app setup, target discovery, launch/status/logs, type
   introspection, queries, mutations, watches, input, screenshots, and cleanup.
   Read [mcp-and-brp.md](references/mcp-and-brp.md).
4. **runtime automation** — direct JSON-RPC script, deterministic control loops,
   window/headless handling, capture freshness, and process ownership. Read
   [runtime-control.md](references/runtime-control.md).
5. **performance and validation** — schedule/system profiling, archetype churn,
   GPU/frame diagnostics, minimal-app tests, visual proof, and build iteration.
   Read
   [performance-and-validation.md](references/performance-and-validation.md).

## Core Rules

- Keep BRP and debug tooling opt-in for development unless product requirements
  explicitly need remote control. Bind local probes to loopback by default.
- Query and record pre-state before mutation. Mutate the narrowest reflected
  path, read back, capture evidence, and restore temporary changes.
- Treat tool success and fresh image hashes as transport proof, not visual or
  gameplay correctness. Inspect resulting state and pixels.
- Never silently upgrade Bevy or third-party plugins to match newer examples.
- Prefer source-owned headless/framebuffer probes. If using a native window,
  size the compositor surface before trusting coordinates or screenshots.

## Cross-Skill Boundaries

- Use `rust-toolkit` for Cargo/workspace, API, typestate, concurrency, unsafe,
  and non-Bevy performance work.
- Use `memory-profiler` for heap leaks, OOM, or allocator forensics.
- Use `nix-toolkit` or `writing-nix` for Nix development environments.
- Use `develop-web-game` only for browser-hosted games; native Bevy uses this
  skill.
