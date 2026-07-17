# Bevy Ecosystem Selection

Use this route when choosing or replacing third-party Bevy crates. Treat crate
popularity and ecosystem labels as discovery signals, not architecture proof.

## Compatibility First

- Lock the app's Bevy version before shortlisting crates. Read each candidate's
  compatibility table, changelog, Cargo features, and release tags.
- Distinguish released engine support from experiments, roadmap items, and
  downstream integrations. Do not design against an announcement alone.
- Check exact target support: desktop backends, WebAssembly/WebGPU or WebGL,
  mobile, headless/minimal apps, and CI runners as applicable.
- Inspect transitive Bevy feature activation. A plugin can silently pull in
  rendering, windowing, audio, or platform dependencies that break minimal
  composition.

## Architecture Fit

- Identify data ownership. Prefer one authoritative representation; if a plugin
  mirrors an external world into ECS, define synchronization direction, timing,
  identity mapping, and failure behavior.
- Inspect plugin and schedule boundaries, component insertion/removal behavior,
  reflection registration, asset ownership, and teardown requirements.
- Keep inspectors, remote control, telemetry, and editor helpers
  development-only unless the product explicitly ships them.
- Native ECS integration can improve ergonomics but does not prove determinism,
  throughput, or lower synchronization cost. Measure the required scenario.

## Category Questions

| Category             | Resolve before selection                                                                                                    |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Physics              | 2D/3D scope, precision, fixed-step contract, determinism/rollback, character control, CCD, spatial queries, debug rendering |
| Input                | device coverage, rebinding, chord conflict policy, analog processing, local multiplayer, serialization                      |
| VFX/vector/rendering | render-world integration, backend limits, shader/assets pipeline, batching, capture behavior, web/mobile fallback           |
| UI/inspection        | maturity, accessibility and text input, reflection exposure, runtime overhead, release gating                               |
| Authoring/DCC        | source of truth, stable IDs, round-trip format, schema sync, coordinate conversion, undo/redo, last-known-good behavior     |
| Networking           | authority model, tick/rollback design, serialization, transport, entity mapping, disconnect/reconnect lifecycle             |

## Bounded Integration Spike

1. Build a minimal app with the exact candidate version and required features.
2. Exercise startup, representative behavior, state transition, teardown, and
   repeated entry.
3. Build or run the riskiest target/backend, not only the development desktop.
4. Measure representative cost and inspect schedule/archetype effects.
5. Remove the plugin from a headless/minimal composition when that boundary is
   required.
6. Record compatibility evidence, known limitations, fallback, and upgrade
   ownership in project documentation.

Compare multiple candidates when the dependency will own persistent data,
simulation, rendering architecture, or a costly migration surface. Prefer the
smallest candidate that satisfies verified requirements.
