# Rigging and deformation

Keep skinning ownership explicit. Automatic weights are a starting hypothesis,
not acceptance evidence. For a bad pose, inspect the rest pose, deform modifier,
vertex-group ownership, normalization, bone envelopes, and affected mesh region.
Nearest-bone or chain-distance heuristics can assign vertices to the wrong bone;
inspect and correct ownership before tuning pose controls.

## Retargeting

Inspect source and target rest poses, bone axes, hierarchy, scale, and root/hip
ownership before mapping motion. Expose the proposed bone correspondence and
unmapped or ambiguous bones before applying it. A count of matched names is not
proof of correct correspondence; resolve consequential ambiguity from the rigs
or ask for missing intent.

Preview representative poses on a separate action or checkpoint. Inspect root
motion, foot contact, joint bending, twist distribution, and deformation before
baking a complete clip. Preserve source actions and target rest data. Confirm
baked action/slot and NLA ownership, then use the export acceptance checks when
producing a runtime clip. Do not delete source actions as automatic cleanup.

## Sources

- [Blender armatures](https://docs.blender.org/manual/en/latest/animation/armatures/index.html)
- [Blender normals](https://docs.blender.org/manual/en/latest/modeling/meshes/editing/mesh/normals.html)
  for face orientation and custom-normal behavior when deformation exposes
  defects.
