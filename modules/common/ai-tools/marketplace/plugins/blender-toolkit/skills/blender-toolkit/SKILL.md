---
name: blender-toolkit
description: Model/review Blender assets.
metadata:
  disable-model-selection: "true"
---

# Blender Toolkit

Treat Blender as an authoring tool. The main result is a checked, editable
source asset. Add a runtime candidate and re-import check for engine/export
tasks. A script, named node, or saved file is not quality evidence by itself.

## Review-only branch

For review-only tasks with supplied images, compare visible evidence, state what
the images cannot establish, and recommend the next correction. Do not execute
Blender, model, render, or export for an image-review-only task. A review within
an already authorized modeling task does not cancel that task's remaining work.

## Establish authority and the target

1. Identify the source scene, current art authority, target runtime/importer,
   coordinate convention, scale convention, and required output format. If
   dimensions are not stated by an authoritative source, label them as inferred
   and keep them editable; do not invent universal units, topology counts, or
   pose/view quotas.
2. Separate visual fidelity from topology and runtime acceptance. Record which
   checks are about likeness or composition and which are about manifoldness,
   normals, material support, skinning, file size, or importer behavior.
3. If operating Blender, discover the installed executable and API version, then
   choose the available interactive, control, or headless workflow. A
   version-matched headless script is valid without MCP/control. Never assume an
   executable path, socket protocol, or `bpy` version.

## Choose a modeling route deliberately

- Choose sculpting, direct topology, or a hybrid from the required editability,
  silhouette, deformation, and runtime constraints. Keep a coherent route for
  the asset instead of endlessly remeshing disconnected primitives.
- For a union, boolean, voxel, or remesh operation, inspect the construction and
  winding of every input first. Establish normals, caps, and ordered
  correspondence for cavity or boundary loops before union or subdivision.
  Recalculating normals after a bad pre-union construction cannot restore lost
  surface intent.

## Inspect effective scene state

Inspect evaluated, connected, visible data rather than names or intended
structure:

- evaluate the modifier stack and check the resulting mesh, face orientation,
  caps, seams, UVs, materials, and object transforms;
- trace material outputs from input to the active surface output. A named shader
  node or broad noise texture that is not connected cannot affect the render;
- render the source scene or an isolated inspection scene after explicitly
  loading the intended `.blend`, selecting the intended collection, and checking
  camera, light, world, visibility, compositor, and render engine state. Treat a
  blank render as invalid evidence, then diagnose scene loading, camera framing,
  visibility, lighting, compositing, and render settings;
- inspect the actual image and runtime import. File freshness, object names,
  node existence, and hashes do not prove visual correctness.

Before details or materials, compare silhouette and proportions from consistent
views beside the authorized art authority. List concrete mismatches, correct the
highest-impact one, and render again. When generated views disagree, record the
camera interpretation and resolve the contradiction without claiming measured
anatomy that the references do not establish.

## Rig, pose, and weights

Keep skinning ownership explicit. Automatic weights are a starting hypothesis,
not acceptance evidence. For a bad pose, inspect the rest pose, deform modifier,
vertex-group ownership, normalization, bone envelopes, and affected mesh region.
Nearest-bone or chain-distance heuristics can assign vertices to the wrong bone;
inspect and correct ownership before tuning pose controls.

For loops around eyes, mouths, cavities, or joints, preserve ordered boundary
correspondence before subdivision. Unordered or mismatched loops can create
subdivision artifacts that hide or distort existing features.

## Preserve checkpoints and export candidates

Maintain editable checkpoints for source construction, topology/material
cleanup, rigging, and approved presentation. When exporting, write a separate
candidate; keep authoring, candidate, and runtime-imported artifacts
distinguishable by path or manifest rather than flattening the only source.

When the task targets glTF/GLB or another runtime format:

1. Export from the intended scene or collection with explicit object,
   visibility, modifier, material, skinning, and animation settings.
2. Re-import into a clean inspection scene or the target runtime. Check
   transforms, scale, winding, normals, UVs, materials, hierarchy, skeleton,
   weights, animation, and missing dependencies.
3. Compare a fixed-view render or runtime capture with the source and inspect
   the imported asset. Record Blender and runtime versions when behavior is
   version-sensitive.

Do not accept a successful export command as proof. The bar is the source
checkpoint, exported candidate, successful re-import, and direct inspection of
resulting visual/runtime behavior.

## Primary references

- [Blender glTF 2.0 manual](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html)
  for exporter scope, evaluated modifiers, collection/visibility filtering, and
  supported animation data.
- [Blender normals manual](https://docs.blender.org/manual/en/latest/modeling/meshes/editing/mesh/normals.html)
  for recalculation, face orientation, and custom normal behavior.
- [Blender Python API](https://docs.blender.org/api/current/) for the discovered
  local version's operators and data API.
- [Bevy assets documentation](https://docs.rs/bevy/latest/bevy/asset/) when the
  candidate is consumed by Bevy; keep source ownership and cold-start import
  checks aligned with the consuming toolkit.
