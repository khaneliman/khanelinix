# Scripted and interactive execution

## Select the control surface

Discover the installed Blender version and the available tool schemas. MCP, TCP,
and WebSocket bridges are different implementations, not interchangeable
protocols; use the configured bridge and its documented capabilities, and do not
install an add-on or start another server because a recipe uses one.

Before a live edit, inspect the active file, scene, mode, selection, and unsaved
work, and scope mutations to the intended collection or objects. Checkpoint
before destructive edits, and never clear the user's scene as initialization.

Prove the live path with MCP tools, not a listening socket: run
`get_blendfile_summary_path_info`, then `get_objects_summary` or equivalent
scene metadata, and capture `get_screenshot_of_window_as_image` or the relevant
`VIEW_3D` area. The metadata must identify the expected file and scene, and the
image must be a real viewport capture.

## Make scripts repeatable

Prefer the data API for context-independent edits. For an operator, check its
installed RNA properties and poll requirements, and set mode, active object,
selection, view layer, and any context override explicitly; a background process
cannot supply an editor area that does not exist. Mark owned data with stable
markers or a generated collection so reruns update only that data and never
duplicate objects, actions, or materials. After a bridge timeout, query the
scene before replaying a mutation; a lost reply does not mean the command
failed.

Keep helper and generator code on disk. Code and state held only in the live
session, including `bpy.app.driver_namespace`, are lost when a file reloads, and
an imported helper module keeps running its old code after its file changes
until `importlib.reload` reloads it.

Blender 5 actions are layered and have no `Action.fcurves`. Walk
`action.layers[].strips[].channelbags[].fcurves`, and guard the legacy attribute
with `hasattr` only in scripts that must also run on older releases.

Viewport-disabled objects can report an identity `matrix_world` after a reload.
After revealing a collection, call `view_layer.update()` and update the
evaluated depsgraph before any world-space edit. Compare source and candidate
under identical collection, view-layer, and object visibility at the same frame
and subframe.

## Run headless jobs

Pass absolute source, script, and output paths. Blender handles arguments in
order, so load the source and set Python failure handling before the script:

```sh
blender --background /absolute/source.blend --python-exit-code 1 \
  --python /absolute/job.py -- --output /absolute/candidate.blend
```

Arguments after `--` belong to the script. For a new isolated scene, use
`--factory-startup` instead of a source file. Do not enable automatic execution
of embedded scripts just to open a third-party asset.

Require a successful exit and the expected outputs, let exceptions fail the
batch, and surface stderr; a script that raises while stderr is discarded looks
like an empty result. Record source path, Blender version, export settings,
outputs, and inspection results outside the installed skill. Validate one
representative asset before a batch, and report per-asset failures rather than
treating partial completion as success.

A Nix-wrapped Blender runs as `.blender-wrappe`, so `ps -C blender` misses it.
Track the PID the launch returned, or match command lines containing
`--background` or `--python`, excluding the live MCP session, whose bootstrap
also passes `--python` and is not a disposable job.

## Save and verify checkpoints

Before saving through MCP, run `bpy.ops.file.make_paths_relative()` so the file
opens from any checkout, then save each step to its own path with
`bpy.ops.wm.save_mainfile(filepath=step_path, compress=True)`; without
`filepath`, the save overwrites the open step. An uncompressed resave grew one
file from 22 MB to 79 MB and left a `.blend1` backup; remove it when the task
keeps its own step checkpoints. Hash protected data before and after a resave or
local edit, such as vertex coordinates, (group, weight) pairs, bone rest heads
and tails, and keyframe points, to prove that only the intended data changed.
Reopen each checkpoint headless and confirm its objects and visibility before
reporting it.

## External assets and previews

Use external libraries only when their assets meet the task. Record the source
URL, asset identity, license or attribution, files, and texture dependencies,
then check scale, orientation, origin, materials, and scene contents after
import. Service APIs and credentials must come from available tools; do not
assume Poly Haven, Sketchfab, or generation-service access.

For thumbnails, turntables, or sprite sheets, set camera and projection,
framing, lighting, color management, resolution, transparency, and frame range
explicitly and hold them across comparison renders. Judge silhouette before
expensive sampling, and inspect the resulting images, including alpha and crop.

## Sources

- [Blender Python API](https://docs.blender.org/api/current/), using the
  discovered local version for operators and the data API.
- [Operator context](https://docs.blender.org/api/current/info_gotchas_operators.html)
- [Command-line arguments](https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html)
