# Export acceptance

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

Blender's glTF importer places helper meshes, such as a bone-display
`Icosphere`, in a `glTF_not_exported` collection and hides the collection, not
the objects, so object visibility flags and scene membership still include them.
Measure bounds from authored meshes only, using the file's mesh-node names as
the whitelist. Imported mesh data names can differ from node names, so map nodes
to meshes explicitly.

## Build a target-specific candidate

Treat transform application as a compatibility decision, not a universal cleanup
step. Check units, local/world transforms, parent inverses, origin, and negative
or non-uniform scale. Avoid changing a bound rig's rest relationship merely to
make transforms look clean. Verify axis conversion in the importer rather than
adding an extra rotation because Blender and the runtime name their axes
differently.

Inspect modifier order on evaluated geometry. Preserve an editable source before
applying topology-changing operations. Shape keys and skinning can constrain
which modifiers the exporter can apply; inspect the installed exporter's options
and warnings rather than forcing a remembered preset.

Applying Subdivision Surface can push vertex weights just above 1.0, and a later
Solidify duplicates the overshoot. `Mesh.validate()` returns true when it
repaired something, so inspect its diagnostics and the weight ranges before and
after each modifier, then revalidate the saved preparation.

Before clearing mesh material slots, snapshot every polygon's material index.
Re-append the materials in order, restore the indices, and assert equality;
clearing first lost face assignments that re-appending did not restore. Recheck
slot coverage after topology-changing modifiers.

For glTF, verify that connected materials use exporter-supported inputs. Bake
unsupported procedural detail into textures when required by the target, then
check UVs, texture color-space interpretation, normal-map convention, alpha
mode, and dependency paths after import. UV seams and hard normals can split
exported vertices, so compare runtime vertex counts against the actual budget,
not only Blender's source mesh count. Apply FBX-specific settings only to FBX
candidates.

When extracting bake or export inputs, resolve the shader connected to the
active Material Output rather than the first Principled node, and keep every
input that drives appearance. Compare the original source against the prepared
copy as well as the prepared copy against the re-import; the second comparison
cannot catch a preparation regression.

The Blender 5.2 glTF exporter drops weights at or below 0.0001, then keeps the
strongest influences up to Bone Influences, 4 by default. Some runtimes, such as
Bevy 0.19, read only `JOINTS_0` and `WEIGHTS_0`. Apply the same cutoff and limit
to the export-prepared skin and normalize it before authoring corrective shape
keys or comparing deformation. Predict the resulting skin delta and compare it
with the observed clean-import error before blaming the runtime.

## Animation acceptance

Identify intended clips and their owners: actions/action slots, NLA tracks,
armatures, and shape keys. Inspect the installed exporter's animation modes; do
not assume every action is exported, or that NLA is required in every mode.
Record clip names, frame range, frame rate, sampling, loop behavior, and root
motion.

Constraints, drivers, simulations, and animated shader graphs need explicit
compatibility checks. Bake supported evaluated motion into exportable channels
when necessary; baking does not make an unsupported channel representable. Check
representative motion and transitions after import, including root trajectory,
joint extremes, foot contacts, shape keys, and clip boundaries.

## Sources

Use documentation matching the discovered Blender/exporter and runtime versions.

- [Blender glTF manual](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html)
- [Apply transforms](https://docs.blender.org/manual/en/latest/scene_layout/object/editing/apply.html)
- [Modifier stack](https://docs.blender.org/manual/en/latest/modeling/modifiers/introduction.html)
- [Bevy assets](https://docs.rs/bevy/latest/bevy/asset/) when Bevy consumes the
  asset; align cold-start import checks with the consuming toolkit.
