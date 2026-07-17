---
name: bevy-toolkit
description: Bevy workflows for ECS, plugin selection, scenes, scheduling, world authoring, diagnostics, validation, and BRP/MCP control. Use when building, debugging, profiling, testing, editing, or automating native Bevy apps.
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
6. **ecosystem selection** — third-party crate compatibility, architecture fit,
   target/backend support, maintenance risk, and bounded integration spikes.
   Read [ecosystem-selection.md](references/ecosystem-selection.md).
7. **world authoring and iteration** — feedback-loop selection, source-of-truth
   ownership, transactional reload, editor/DCC bridges, and persisted edits.
   Read [authoring-pipelines.md](references/authoring-pipelines.md).

## Core Rules

- Keep BRP and debug tooling opt-in for development unless product requirements
  explicitly need remote control. Bind local probes to loopback by default.
- Query and record pre-state before mutation. Mutate the narrowest reflected
  path, read back, capture evidence, and restore temporary changes.
- Treat live editor and BRP mutations as ephemeral unless an explicit authoring
  command persists them to source-owned data.
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
