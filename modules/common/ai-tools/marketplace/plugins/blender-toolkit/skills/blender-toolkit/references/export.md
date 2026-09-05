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

For glTF, verify that connected materials use exporter-supported inputs. Bake
unsupported procedural detail into textures when required by the target, then
check UVs, texture color-space interpretation, normal-map convention, alpha
mode, and dependency paths after import. UV seams and hard normals can split
exported vertices, so compare runtime vertex counts against the actual budget,
not only Blender's source mesh count. Apply FBX-specific settings only to FBX
candidates.

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
