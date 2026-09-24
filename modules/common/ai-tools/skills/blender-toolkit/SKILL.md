---
name: blender-toolkit
description: Author, inspect, rig, render, export, or review Blender game assets with editable source files and re-import checks. Use for .blend modeling, topology or normals repair, glTF export validation, or image-based asset review.
metadata:
  disable-model-selection: "true"
---

# Blender Toolkit

Blender is the authoring tool. The deliverable is a checked, editable source
asset, plus a runtime candidate and re-import check for engine or export tasks.
A script, named node, or saved file is not quality evidence by itself.

## Review-only branch

For review-only tasks with supplied images, compare the visible evidence, state
what the images cannot establish, and recommend the next correction without
running Blender. A review inside an authorized modeling task does not end that
task.

## Establish authority and the target

1. Identify the source scene, art authority, target runtime or importer,
   coordinate and scale conventions, and output format. Label dimensions and
   camera choices no authoritative source states as inferred and keep them
   editable; do not invent units, topology counts, or pose or view quotas.
2. Keep visual checks, such as likeness and composition, separate from topology
   and runtime checks, such as normals, skinning, material support, file size,
   and importer behavior.
3. Discover the installed executable and API version; never assume a path,
   socket protocol, or `bpy` version. When MCP is requested, verify the live
   path before modeling and report a blocker instead of silently falling back;
   otherwise headless Blender is valid when the task permits it and its checks
   can run. Read [automation](references/automation.md) before scripted or live
   control.

## Choose a modeling route deliberately

- Choose sculpting, direct topology, or a hybrid from the editability,
  silhouette, deformation, and runtime needs, and keep one coherent route
  instead of endlessly remeshing disconnected primitives.
- For humanoid characters, start from a licensed base mesh with production eye
  and mouth loops. Read
  [character construction](references/character-construction.md) before building
  or reshaping anatomy, eyes, hair, or part junctions.
- Before a union, boolean, voxel, remesh, or subdivision, inspect each input's
  construction and winding, and establish normals, caps, and ordered
  correspondence for boundary loops around eyes, mouths, cavities, and joints.
  Mismatched loops hide or distort features under subdivision, and recalculating
  normals afterwards cannot restore lost surface intent. Read
  [mesh surgery](references/mesh-surgery.md) before bridging boundaries, cutting
  openings, or solving vertex positions in code.

## Inspect effective scene state

Inspect evaluated, connected, visible data rather than names or intended
structure:

- evaluate the modifier stack and check the resulting mesh, face orientation,
  caps, seams, UVs, materials, and object transforms;
- census every visible object type, including curves, separate eye or lid
  meshes, and fur, before attributing a feature to one mesh;
- trace materials to the active surface output; an unconnected node cannot
  affect the render;
- render only after explicitly loading the intended `.blend` and collection and
  checking camera, lights, world, visibility, compositor, and engine; a blank
  render is a setup fault to diagnose, not evidence;
- inspect the actual image and runtime import; file freshness, object names,
  node existence, and hashes do not prove visual correctness.

Before the first edit for artwork matching, character likeness, or repeated
visual corrections, read the
[visual iteration loop](references/visual-iteration.md), which owns inspection
renders, comparisons, correction order, and visual acceptance.

## Rig, pose, and weights

For skinning, pose correction, or retargeting, read
[rigging](references/rigging.md) before changing the rig.

## Preserve checkpoints and export candidates

Keep editable checkpoints for construction, cleanup, rigging, and approved
presentation, and export to a separate candidate so source, candidate, and
re-imported artifacts stay distinguishable by path or manifest. For glTF/GLB,
FBX, or other runtime candidates, read
[export acceptance](references/export.md); a successful export command is not
proof of a usable asset.
