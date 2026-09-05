# Scripted and interactive execution

## Select the control surface

Discover the installed Blender version and available tool schemas. MCP, TCP, and
WebSocket bridges are different implementations, not interchangeable Blender
protocols. Use the configured bridge and its documented capabilities; do not
install an add-on or start another server merely because a recipe uses it. If
live control is unavailable, use headless Blender when the task permits it.

Before a live edit, inspect the active file, scene, mode, selection, and unsaved
work. Scope mutations to the intended collection or objects. Keep a checkpoint
before destructive edits; never clear the user's scene as initialization.

## Make scripts repeatable

Prefer the data API for context-independent edits. When an operator is needed,
check its installed RNA properties and polling requirements. Establish mode,
active object, selection, view layer, and any required context override
explicitly. A background process cannot supply an editor area that does not
exist.

Use stable ownership markers or an explicit generated collection so reruns
update only owned data. A retry must not duplicate objects, actions, or
materials. After a bridge timeout, query the resulting state before replaying a
mutation: a lost reply does not establish that the command failed.

For headless jobs, pass absolute source, script, and output paths. Blender
handles arguments in order: load the intended source before running the script,
and set Python failure handling before the script. A typical existing-file
invocation is:

```sh
blender --background /absolute/source.blend --python-exit-code 1 \
  --python /absolute/job.py -- --output /absolute/candidate.blend
```

The `--output` argument belongs to the task's script, not Blender; parse script
arguments after `--`. For a new isolated scene, use `--factory-startup` instead
of loading a source file. Do not enable automatic execution of embedded scripts
just to open a third-party asset.

Require both a successful process exit and the expected outputs. Keep logs and
record source path, Blender version, export settings, output paths, and
inspection results outside the installed skill. Do not swallow exceptions that
should fail a batch. Validate one representative asset before processing the
full batch; report per-asset failures without treating partial completion as
full success.

## External assets and previews

Use external libraries only when their assets meet the task. Record source URL,
asset identity, license/attribution, downloaded files, and texture dependencies.
Check scale, orientation, origin, material compatibility, and scene contents
after import. Service-specific APIs and credentials must come from available
tools, not assumed Poly Haven, Sketchfab, or generation-service access.

For thumbnails, turntables, or sprite sheets, keep camera/projection, framing,
lighting, color management, resolution, transparency, and frame range explicit.
Fix those settings across comparison renders. Judge silhouette before expensive
render sampling. Inspect the actual resulting images, including alpha and crop;
file existence alone does not prove the preview contains the asset.

## Sources

- [Blender Python API](https://docs.blender.org/api/current/), using the
  discovered local version for operators and the data API.
- [Operator context](https://docs.blender.org/api/current/info_gotchas_operators.html)
- [Command-line arguments](https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html)
