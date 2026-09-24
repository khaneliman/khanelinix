# Rigging and deformation

Automatic weights are a starting hypothesis, not acceptance evidence. For a bad
pose, inspect the rest pose, deform modifier, vertex-group ownership,
normalization, bone envelopes, and affected region. Nearest-bone or
chain-distance heuristics can assign vertices to the wrong bone; correct
ownership before tuning pose controls.

## Isolate deformation failures

Inspect the loaded source for an armature and vertex groups rather than trusting
a file label or old report. Before correcting a garment or pose, confirm that
the rendered pose is the requested one: inspect evaluated bone endpoints, select
the action slot explicitly, and mute NLA without deleting either. Then render
the bare body in the same pose and camera, and audit body and garment
deformation separately; one body edge that stretched 31.5 times between rest and
reach was a body fault no garment edit could fix. Standing clearance does not
establish pose clearance; check triangle intersections, not vertex-distance
samples, through the transition into the pose.

An exact rig transfer preserves existing skin defects, so check the rest pose
for intersections before blaming a retarget. Short, disconnected display bones
do not mark joints; build limb chains from the ordered joint heads and preserve
display lengths and bind matrices.

Constrain garment weight transfer by panel ownership, such as the torso and each
sleeve, with mixed donors only at shared seams. Nearest-surface distance is not
anatomical correspondence: hands resting near a hem gave it arm weights, and
crawling pulled the torso into flaps.

A direct pose-bone assignment can match an IK target in a snapshot and then be
erased when rendering re-evaluates the active action. Key the study pose into a
separate action copy, re-evaluate its frame, and reopen the saved file before
trusting it.

## Retargeting

Inspect source and target rest poses, bone axes, hierarchy, scale, and root or
hip ownership before mapping motion. Show the proposed bone correspondence and
unmapped or ambiguous bones before applying it; matched name counts do not prove
correspondence, so resolve consequential ambiguity from the rigs or ask. Test a
proposed cause with a measurement that could falsify it: comparing animated
segment directions with rest directions ruled out an arm-translation cause that
the largest discarded translation had suggested.

Preview representative poses on a separate action or checkpoint, and inspect
root motion, foot contact, joint bending, twist distribution, and deformation
before baking a full clip. Preserve source actions and target rest data, confirm
baked action, slot, and NLA ownership, and use the export acceptance checks for
a runtime clip. Do not delete source actions as automatic cleanup.

## Sources

- [Blender armatures](https://docs.blender.org/manual/en/latest/animation/armatures/index.html)
- [Blender normals](https://docs.blender.org/manual/en/latest/modeling/meshes/editing/mesh/normals.html)
  for face orientation and custom-normal behavior when deformation exposes
  defects.
