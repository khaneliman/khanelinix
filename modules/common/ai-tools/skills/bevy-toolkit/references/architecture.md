# Bevy ECS and Plugin Architecture

## Intake

Record app targets, Bevy version/features, plugin compatibility, supported
platforms, states/schedules, headless needs, asset pipeline, and current query
hotspots. Inspect project-local architecture docs before applying generic ECS
patterns.

## Domain Plugins

- Organize plugins around cohesive gameplay/application capabilities, not one
  plugin per component or system.
- Keep plugin `build` focused on registration: reflected types, resources,
  events/messages, observers, schedules, systems, and child plugins.
- Expose subplugins when headless servers, tests, editors, or feature flags need
  different composition.
- Keep deterministic simulation independent from rendering, audio, input, and
  remote-debug adapters when alternate composition benefits.
- Put cross-plugin ordering at the integration boundary. Avoid hidden `.before`
  or `.after` contracts spread across leaf modules.

## ECS Data Shape

- Use components for per-entity state and resources for truly world-global
  state. Do not turn resources into service locators.
- Keep hot query data focused. Split components when systems access disjoint
  fields or fields change at different rates; require query/profile evidence.
- Treat component insertion/removal as archetype movement and lifecycle change,
  not a free flag toggle.
- Keep world-dependent behavior in systems/commands. Component methods remain
  useful for local invariants and pure transformations.
- Prefer explicit marker components over string/name matching for runtime logic;
  add `Name` for diagnostics and BRP discovery.

## Relationships and Scenes

- Use relationships/hierarchies only when ownership, propagation, and recursive
  teardown semantics are explicit.
- Keep imported scene roots as presentation children when gameplay collision,
  interaction, save identity, or lifecycle belongs to a stable wrapper entity.
- Use required components, bundles, scenes, or spawn helpers according to the
  locked Bevy version and whether the contract is structural, reusable, or
  data-authored. Do not replace every spawn with the newest mechanism.
- Keep data-authored scene/layout hot reload scoped to one owner. Rebuild the
  changed subtree instead of respawning unrelated world state.

## Boundaries and Reflection

- Register only types that need scenes, serialization, inspector/BRP access, or
  dynamic construction. Reflection expands debug and mutation surface.
- Give remote-control resources explicit request/status/identity fields so
  automation can reject stale responses and wrong sessions.
- Keep debug-only reflection and BRP plugins behind a feature when release
  binaries should not expose them.
- Split crates only for independent targets, dependencies, release units,
  proc-macros, or measured recompilation isolation. Plugin boundaries normally
  belong inside one crate first.

## Review Questions

1. Which plugin owns each resource, event/message, state transition, and
   cleanup?
2. Which systems need same-frame order versus ordinary data conflict ordering?
3. Can headless/minimal tests omit rendering and platform plugins?
4. Does a scene hierarchy encode presentation, gameplay ownership, or both?
5. Which types must be remotely mutable, and which should remain unregistered?
