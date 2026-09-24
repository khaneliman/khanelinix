# Rigging and deformation

Keep skinning ownership explicit. Automatic weights are a starting hypothesis,
not acceptance evidence. For a bad pose, inspect the rest pose, deform modifier,
vertex-group ownership, normalization, bone envelopes, and affected mesh region.
Nearest-bone or chain-distance heuristics can assign vertices to the wrong bone;
inspect and correct ownership before tuning pose controls.

## Isolate deformation failures

Do not infer a rig from a file label or an old report; inspect the loaded source
for an armature and vertex groups. Before correcting a garment or pose, confirm
that the rendered pose is the requested one. Inspect evaluated bone endpoints,
and isolate inherited actions and NLA influence by selecting the action slot
explicitly and muting NLA, without deleting either. Then render the bare body in
the same pose and camera. Audit body and garment deformation separately; one
body edge that stretched 31.5 times between rest and reach marked a body
transition fault that no garment edit could fix. Standing clearance does not
establish pose clearance, and vertex-distance samples do not certify triangle
intersections or the transition into a pose.

An exact rig transfer preserves existing skin defects, so check the rest pose
for intersections before blaming a retarget. Short, disconnected display bones
do not mark anatomical joints; build limb chains from the ordered joint heads
and preserve display lengths and bind matrices.

Constrain garment weight transfer by panel ownership, such as the torso and each
sleeve, with mixed donors only at shared seams. Nearest-surface distance is not
anatomical correspondence: hands resting near a hem gave it arm weights, and
crawling then pulled the torso into flaps.

A direct pose-bone assignment can match an IK target in a snapshot and then be
erased when rendering re-evaluates the active action. Key the study pose into a
separate action copy, re-evaluate its frame, and reopen the saved file before
trusting it; a pose rendered before saving does not prove that its action
survived.

## Retargeting

Inspect source and target rest poses, bone axes, hierarchy, scale, and root/hip
ownership before mapping motion. Expose the proposed bone correspondence and
unmapped or ambiguous bones before applying it. A count of matched names is not
proof of correct correspondence; resolve consequential ambiguity from the rigs
or ask for missing intent. Test a proposed cause with a measurement that could
falsify it. Comparing animated segment directions with rest directions ruled out
an arm-translation cause that the largest discarded translation had suggested.

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
