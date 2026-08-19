# Bevy MCP and BRP

`bevy_brp_mcp` is an MCP stdio server used by the coding agent. The running game
exposes Bevy Remote Protocol over HTTP. Keep these two connections distinct when
diagnosing discovery, tool availability, or game reachability.

## Contents

- [Compatibility and App Setup](#compatibility-and-app-setup)
- [Lifecycle Workflow](#lifecycle-workflow)
- [Introspection Before Mutation](#introspection-before-mutation)
- [Queries and Reads](#queries-and-reads)
- [Mutations and Events](#mutations-and-events)
- [Input, Capture, and Diagnostics](#input-capture-and-diagnostics)
- [Watches, Logs, and Cleanup](#watches-logs-and-cleanup)
- [Failure Routing](#failure-routing)

## Compatibility and App Setup

Inspect installed MCP/extras and locked Bevy versions before editing. The
package version, upstream compatibility table, and live `brp_tool_help` output
are authoritative; do not copy a previously observed version from this skill.

Core BRP requires Bevy's remote feature and remote plugins. `bevy_brp_extras`
can register core BRP plus screenshots, diagnostics, keyboard/mouse input,
window title, and clean shutdown. Keep either setup development-only when remote
control must not ship in normal/release binaries.

Defaults and caveats:

- Default port: `15702`; extras supports `BRP_EXTRAS_PORT`.
- Bind to loopback unless remote access is explicit and protected by an
  application-owned authentication, authorization, and method-allowlist layer.
- Extras screenshots require Bevy's `png` feature.
- Extras diagnostics require its `diagnostics` feature (default-on upstream).
- Custom `RemoteHttpPlugin` owns transport/port; extras port settings are then
  ignored.
- Release-appropriate core BRP may expose the render subapp on a second port.
  Discover support before assuming main-world and render-world visibility.

## Lifecycle Workflow

Prefer this sequence:

1. `brp_list_bevy`: discover declared apps/examples, package identity, BRP
   support level, profiles, build status, and paths.
2. `brp_status`: detect existing process/port before launch.
3. `brp_tool_help`: read the live parameter contract before a nontrivial or
   unfamiliar tool call.
4. `brp_launch`: launch a target already configured with required Cargo
   features, supplying supported package/path, profile, args, environment,
   instance, and port fields deliberately. Use a repository launcher when
   features must be selected at launch time.
5. Poll `brp_status` until `running_with_brp`; read returned log path when
   launch or startup fails.
6. Perform inspect/control/verification work.
7. `brp_shutdown`: prefer extras clean shutdown; MCP may fall back to its owned
   process termination.

Do not launch a second app onto an occupied BRP port. For multiple instances,
assign sequential/explicit ports and carry port plus app/session identity into
every tool call.

## Introspection Before Mutation

- Use `brp_type_guide` for every component/resource type being spawned,
  inserted, or mutated. Pass fully qualified reflected type names.
- Check `reflect_types`: `Component` and `Resource` determine supported
  operations; mutation also requires mutable reflected fields.
- Use `registry_schema` or `brp_all_type_guides` only when broad schema
  discovery is needed; their responses can be large.
- Use `rpc_discover` when diagnosing available BRP methods or extras mismatch.
- Use `brp_tool_help` for exact MCP parameter names and shapes instead of
  treating examples in this reference as a second tool schema.
- Prefer project-owned `Name`, marker components, request/session resources, and
  stable IDs over entity numbers copied from an older run.

## Queries and Reads

Pass MCP parameters as objects, not JSON strings.

For `world_query`:

- `data: {}` returns matching entity IDs only.
- `data.components` requires and returns listed component data.
- `data.option` returns optional components; `"all"` is broad and expensive.
- `data.has` returns presence booleans.
- `filter.with` and `filter.without` constrain matching entities.

Use `world_get_components` after resolving current entity IDs. Use
`world_get_resources` for global/config/request state. Read the smallest useful
set and record pre-state before control actions.

## Mutations and Events

Use type-guide mutation paths exactly:

- root replacement: `""`
- nested field: `.translation.y`
- array: `.points[2]`
- tuple: `.0`
- map: `.scores['player1']`

Prefer `world_mutate_components` / `world_mutate_resources` over whole-value
replacement. Verify result with a get/query call. Restore temporary mutation
after capture or diagnosis.

Use `world_trigger_event` only for events registered/reflected for BRP and when
observer semantics are intended. Prefer project-owned request resources for
long-running actions because they can carry request ID, status, progress, and
error state across frames.

Register project-owned custom BRP methods for deterministic reset, save/load,
fixture setup, or assertions when raw ECS mutation cannot express the operation
safely. Give each method narrow inputs, explicit authorization, request/session
identity, bounded work, and readback status.

## Input, Capture, and Diagnostics

These are adapter capabilities, not core BRP guarantees. Use
[runtime-control.md](runtime-control.md) for end-to-end sequencing and proof.
With `bevy_brp_extras`:

- `brp_extras_send_keys` sends a simultaneous chord and complete
  press-hold-release cycle. Use Bevy `KeyCode` names such as `KeyA`, `Space`, or
  `ShiftLeft`; set `duration_ms` for held input.
- `brp_extras_type_text` queues characters one per frame. Use it for text
  fields, not chords.
- Mouse move supports absolute position or delta; click/drag/scroll operate in
  game-window coordinates. Verify actual window and compositor size first.
- `brp_extras_screenshot` writes a game framebuffer image. Use a unique absolute
  path, then verify existence, nonzero size, freshness, and pixels.
- `brp_extras_get_diagnostics` returns current/average/smoothed FPS and frame
  time. Warm the scenario before comparing measurements.

## Watches, Logs, and Cleanup

Component/list watches run asynchronously and write logs. Track returned watch
IDs/log paths, bound observation duration, stop watches, and delete only logs
owned by the current task. Do not leave a watcher as an implicit assertion.

Use `brp_list_logs` / `brp_read_log` for MCP-launched game and watch logs. Use
the trace-level tools only for bounded MCP/BRP protocol diagnosis; restore
normal tracing and remove task-owned trace logs afterward.

## Failure Routing

| Symptom                                  | Check                                                                 |
| ---------------------------------------- | --------------------------------------------------------------------- |
| MCP tool absent                          | khanelinix `enabled_tools`, deployed config, new agent session        |
| App listed with `brp_level: none`        | remote feature/plugin registration for target source                  |
| `running_no_brp`                         | launched wrong binary/features or remote plugin disabled              |
| Connection refused                       | port/process, readiness timeout, game log                             |
| Method not found                         | extras absent/version mismatch; inspect `rpc_discover`                |
| Unknown type/path                        | current registry/type guide and fully qualified type name             |
| Mutation succeeds but behavior unchanged | wrong entity/session, deferred logic, owner system overwrote field    |
| Input missed                             | use frame-aware extras calls; verify focus/window/state and read back |
| Screenshot empty                         | `png` feature, render-capable app, destination permissions            |
| Tiled/duplicated native capture          | resize compositor surface, not only Bevy resolution                   |

Upstream source: [natepiano/bevy_brp](https://github.com/natepiano/bevy_brp).
