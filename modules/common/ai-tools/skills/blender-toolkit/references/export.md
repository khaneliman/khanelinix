# Export acceptance

1. Export from the intended scene or collection with explicit object,
   visibility, modifier, material, skinning, and animation settings.
2. Re-import into a clean inspection scene or the target runtime and check
   transforms, scale, winding, normals, UVs, materials, hierarchy, skeleton,
   weights, animation, and missing dependencies.
3. Compare a fixed-view render or runtime capture with the source, and record
   Blender and runtime versions when behavior is version-sensitive.

Acceptance needs the source checkpoint, the exported candidate, a successful
re-import, and direct inspection of the result.

Blender's glTF importer puts helper meshes, such as a bone-display `Icosphere`,
in a `glTF_not_exported` collection and hides the collection, not the objects,
so object visibility and scene membership still include them. Measure bounds
from authored meshes only, whitelisting the file's mesh-node names, and map
nodes to meshes explicitly because imported mesh data names can differ.

## Build a target-specific candidate

Treat transform application as a compatibility decision, not routine cleanup.
Check units, local and world transforms, parent inverses, origin, and negative
or non-uniform scale, and do not change a bound rig's rest relationship to make
transforms look clean. Verify the importer's axis conversion instead of adding a
rotation because Blender and the runtime name axes differently.

Inspect modifier order on evaluated geometry and keep an editable source before
applying topology-changing modifiers. Shape keys and skinning limit which
modifiers the exporter can apply; read the installed exporter's options and
warnings rather than a remembered preset.

Applying Subdivision Surface can push vertex weights just above 1.0, and a later
Solidify duplicates the overshoot. `Mesh.validate()` returns true when it
repaired something, so check its diagnostics and the weight ranges around each
modifier, then revalidate the saved preparation.

Snapshot every polygon's material index before clearing slots, then re-append
the materials in order, restore the indices, and assert equality; clearing first
lost face assignments that re-appending did not restore. Recheck slot coverage
after topology-changing modifiers.

For glTF, check that materials use exporter-supported inputs, and bake
unsupported procedural detail when the target requires it. After import, check
UVs, texture color space, normal-map convention, alpha mode, and dependency
paths. UV seams and hard normals split exported vertices, so budget against the
runtime vertex count, not Blender's source count. Apply FBX-specific settings
only to FBX candidates.

When extracting bake or export inputs, resolve the shader connected to the
active Material Output, not the first Principled node, and keep every input that
drives appearance. Compare the original source with the prepared copy as well as
the prepared copy with the re-import; only the first catches a preparation
regression.

The Blender 5.2 glTF exporter drops weights at or below 0.0001, then keeps the
strongest influences up to Bone Influences, 4 by default, and some runtimes,
such as Bevy 0.19, read only `JOINTS_0` and `WEIGHTS_0`. Apply the same cutoff
and limit to the export-prepared skin and normalize it before authoring
corrective shape keys or comparing deformation, and predict the resulting skin
delta before blaming the runtime for a clean-import error.

## Animation acceptance

Identify intended clips and their owners: actions and slots, NLA tracks,
armatures, and shape keys. Check the installed exporter's animation modes rather
than assuming every action exports or that NLA is always required. Record clip
names, frame range, frame rate, sampling, loop behavior, and root motion.

Constraints, drivers, simulations, and animated shader graphs need explicit
compatibility checks. Bake supported evaluated motion into exportable channels
when necessary; baking cannot represent an unsupported channel. After import,
check root trajectory, joint extremes, foot contacts, shape keys, and clip
boundaries.

## Sources

Use documentation matching the discovered Blender/exporter and runtime versions.

- [Blender glTF manual](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html)
- [Apply transforms](https://docs.blender.org/manual/en/latest/scene_layout/object/editing/apply.html)
- [Modifier stack](https://docs.blender.org/manual/en/latest/modeling/modifiers/introduction.html)
- [Bevy assets](https://docs.rs/bevy/latest/bevy/asset/) when Bevy consumes the
  asset; align cold-start import checks with the consuming toolkit.
