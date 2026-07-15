# Bevy Performance and Validation

## Measurement Ladder

1. Reproduce with fixed scene, camera, inputs, feature set, profile, and window.
2. Capture frame time/FPS diagnostics and system/schedule evidence.
3. Separate CPU simulation, render extraction, GPU, asset, and build-time cost.
4. Change one variable and repeat the same probe.
5. Keep recommendation conditional when no comparable baseline exists.

## ECS and Schedule Cost

- Inspect entity counts, query cardinality, archetype count/churn, change
  detection, command queues, and system conflicts.
- Reduce repeated projections or broad world scans only after locating callers
  and proving data ownership/invalidation.
- Treat `Changed<T>` as Bevy change detection, not semantic value inequality.
- Keep fixed-step simulation and variable presentation responsibilities clear.
- Avoid adding caches whose invalidation is broader or less reliable than the
  work they replace.

## Rendering and Assets

- Profile shadows, lights, transparent materials, particles, overdraw, camera
  stacks, render layers, post-processing, and asset uploads with representative
  views.
- Keep visual quality changes reversible and compare source-owned captures.
- Verify imported scene scale against known-size world props before rescaling
  collision or world coordinates.
- Use headless GPU/framebuffer capture when supported. A no-window ECS test does
  not validate rendering.

## Build Iteration

- Compare existing profiles before adding Bevy dependency optimization, dynamic
  linking, alternative linkers, or feature reduction.
- Measure clean and incremental paths separately.
- Keep stable CI/release fallback when development uses dynamic linking or an
  alternative codegen backend.
- Use `rust-toolkit` for Cargo timing, dependency, allocator, or generic Rust
  optimization decisions.

## Validation Matrix

| Change                | Minimum proof                                            |
| --------------------- | -------------------------------------------------------- |
| ECS/state logic       | Minimal-App test plus focused project test               |
| Scheduling/order      | Focused transition test and schedule graph when needed   |
| BRP/reflection        | Type guide/query, mutation/readback, cleanup             |
| Input behavior        | Frame-aware injected input and resulting state assertion |
| Camera/layout/scale   | Fixed-view framebuffer capture and pixel inspection      |
| Rendering/performance | Same-scene diagnostics/profile before and after          |
| Asset hot reload      | Changed asset rebuilds only owned subtree                |

## Visual Proof

- Record session/request identity, camera transform, window/surface size, output
  path, file size, modification time, and hash.
- Reject stale files and wrong live sessions.
- Inspect image contents. Hashes prove freshness/distinctness, not correctness.
- Avoid compositor screenshots through lock screens or overlays.
- For native windows, match compositor surface to expected game resolution
  before injecting coordinate-based input or capturing the window.

## Reporting

Separate executed checks, observed metrics, visual observations, hypotheses, and
checks not run. Include exact app target, Bevy version, features, profile, BRP
port/session, and whether a real desktop window was opened.
