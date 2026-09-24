# Character construction

## Start from production topology

Hand-built eye and mouth regions failed repeatedly; a base mesh with concentric
eye and mouth loops and clean quad flow was a large quality step, though its eye
still needed rescaling and lids. CC0 candidates, checked against primary sources
on 2026-09-16:

- Blender Studio Human Base Meshes, from
  `mirror.blender.org/demo/asset-bundles/human-base-meshes/` (the blender.org
  link is an interstitial page);
- MakeHuman and MPFB2 core assets (the code is AGPL/GPL, and community assets
  carry their own licenses);
- thebasemesh.com.

Share one topology across a humanoid cast so weights, one UV layout, garments,
and deformation fixes transfer by vertex correspondence, and keep each identity
as a position delta from the base. Measure a base before trusting it: one stock
stylized eye was about twice life proportion, a closed head tapered to a near
point at the neck, and adult and stylized bases still need reproportioning.

## Build small anatomy from primitives

Metaballs of 5 to 8 mm radius did not fuse at the default threshold in Blender
5.2; overlapping mesh primitives unioned by a voxel Remesh modifier were
predictable. Space spheres about 0.3 of their radius apart, or the union beads.
Keep the voxel well below the narrowest gap that must stay open (0.8 mm kept 2.5
mm finger gaps open), then add a Smooth modifier; remesh rings on a smooth
cylinder need more Smooth iterations, not a finer voxel (6 left stair-steps, 22
cleared them). Check smoothing before concluding that a form is wrong. Jitter
primitive rotations and scale subdivision with radius, or aligned facets along a
tube reinforce into bands.

`bmesh.ops.bevel` defaults to `affect='VERTICES'`, which leaves a cube's edges
sharp; use `affect='EDGES'` with `clamp_overlap=True` for a rounded solid. For a
flattened mass such as a palm, bevel a near-cube by about 0.6 of the half-extent
and then scale the thickness axis so the rounding survives on every axis; an
ellipsoid reads as a ball. Taper one slab instead of stacking slabs, which
leaves a step, carve concavities instead of gluing masses beside them, and seat
limb roots about 30 percent of a segment inside the parent so the junction
blends.

Keep part generators parametric over a saved parameter file and writing only
into their own collection. A cross-section remap cannot separate digits;
construct fingers and toes. Vertex count is not form: a mesh of over 100,000
vertices can still be a mannequin.

## Edit an existing surface directly

Edit an accepted mesh in place with small brush edit lists, each applied to the
previous step's blend. Overlapping parameter layers over one region fight, so
reserve them for global reproportioning. Useful brushes are grab (translate a
falloff region), relax (falloff-weighted Laplacian), and scale or shell (scale
about a pivot with a ramp), with ellipsoid radii, per-axis delta masks, and
zero-weight fences.

- Give every falloff an inner plateau: a smoothstep of `(1 - d)` gave a feature
  at `d = 0.7` about 17 percent of its move and a region-wide scale about half.
- Keep mirrored regions off the midline, for example
  `abs(centre.x) / radius.x > 1`; overlapping mirrors partly cancelled lateral
  deltas and summed vertical ones.
- Mirror signed offsets explicitly; `copysign(inset * w, sx)` drops the sign of
  `inset`, so a negative inset never pushes outward.
- Weight a narrowing scale by distance from the midline, such as
  `(abs(x) / xref) ** p`, or it drags the eyes, nose, and mouth sideways, and
  scale only the dimension that is wrong.
- Relax removes relief but cannot make form, and it can move a saddle such as
  the nasion the wrong way; grab the feature's own loops instead.
- An occluding contour, such as a nostril shelf seen from the front, is not a
  crease that displacement can remove; remodel the loop or rotate the plane.
- Re-measure before reusing an op on another asset; a push that laid lid skin
  onto one eyeball buried another under socket floor.
- Stylized child faces need fuller cheeks and much gentler brow, socket, nose,
  and lip relief than adult amounts, which gave a heavy brow over hollow orbits.

Select rim and jaw loops topologically: at each far vertex, take the edge that
shares no face with the current edge, stop at poles, and let a mirrored
positional gate with a plateau set how much of the loop moves. Put the freeze
wall on the nearest loop that must stay fixed, not the moved loop, or the next
ring cannot follow and the move digs a trench. Check selections with markers
first; a marker on a cage vertex hides in concave regions, where the subdivided
surface sits outside the cage.

## Protect seams from displacement

Sealed lips and lids can be coincident but separate shells. Displacement along
vertex normals splits those pairs into crust along the seam, while a
position-only translation moves both copies together; a relax across a lip line
even parted a head with no coincident pairs. Before and after each edit, count
pairs with a KDTree at several tolerances, such as 0.1, 0.2, and 0.5 mm, on the
evaluated subdivided mesh as well as the cage. One head had 0 pairs on the cage
and 34 evaluated, and new evaluated pairs caught a fold that the whole-face
check passed. Fence near-seams with zero weight; zero pairs at one tolerance is
not proof of safety.

When a defect appears near a feature, bisect the edit list before editing that
feature; the responsible op can sit elsewhere, as a cheek inflate overlapping a
lip corner did through seven mouth reshapes.

## Move whole features

- Snap every vertex below full weight back to the nearest point of the pre-move
  surface, or a move over a curved skull lifts falloff skin off it; a 16 mm ear
  move done that way left no bump.
- Fence neighbouring features such as ears out of a regional taper, and end the
  taper at a natural boundary; a jaw taper stopped at ear-lobe height left a
  cheek bulge.
- After each move, rebuild object-space projected paint, such as lip and blush
  masks, and re-seat fitted pieces such as hair locks, lashes, and accessories.

## Eyes

- Resize an eye as one unit, scaling the ball and the head's lid region together
  about the cornea point, the front of the ball on its axis, so lid clearance
  stays proportional; ball-only, aperture-only, and translation edits failed on
  three heads. Seat the lid margin a few millimetres in front of the cornea.
- Scale a surface detail only in its own plane, about the host's post-edit
  centre, and check its depth range against the host; scaling an iris uniformly
  about the eyeball centre lifted it 15 mm off the ball.
- Build lids from the head's aperture loops by pushing the margin ring forward
  and grabbing a shallow fold one ring above; separate lid objects read as tubes
  on a sculpted head.
- Measure clearance against the actual ball, read as an ellipsoid after any
  rescale, and track the lid-margin ring per sector. A vertex inside the ball is
  harmless only when it is socket floor; lid skin inside it means the ball cuts
  through the lid.
- A closed head has no boundary edges at the lids; trace the opening with
  front-view ray casts that hit the ball before the head.
- Some stylized eyes, including Blender Studio's, have a concave iris dish and
  pupil well that show as a ring and step in clay and mirror the glint to the
  wrong side of the pupil. Paint pupil, iris, and sclera by radius from the
  eye's forward axis in Object coordinates, gated to the ball's front, which
  hides the ring and step; keep the ball rough and paint the catchlight.
- Seat lids against the evaluated ball mesh, sampled densely; contact computed
  for an analytic sphere left a scalloped aperture on a coarse globe.

## Hair, beards, and fur

Build silhouette block-ins as closed smooth volumes from a front sheet, a
reversed back sheet, and a rim strip, with zero open edges; a face region offset
along its normals renders as a slab with a boundary crease and a serrated edge.
Build the block-in before judging head width or skull size; on one head it
reversed two of three inherited faults.

- No constant inset works: deep offsets self-intersect in concave regions,
  shallow ones poke through thin flanges such as ears, and outward ones stand
  proud. Scale inset and wall thickness by local head thickness from an inward
  BVH ray, graded to the reference hair.
- Route hair and beard lines around thin flanges instead of cutting holes, and
  drop faces over very thin regions. Restrict cut-out dilation around a flange
  to unused vertices and add a zero-weight apron, or it eats live hair and
  exposes the rim.
- Relax lifts the offset weight at a mesh cut by averaging toward the interior;
  pin the weight to zero for one ring and ramp back over three.

For directional fur, project the desired direction onto the surface with
`t = d - n * dot(d, n)`; straight down, `d = (0, 0, -1)`, gives `d + n * n.z`,
and the opposite sign combs upper fibers inward. When replacing a groom, census
older curve layers; a retained curve object kept old strands visible through
several nominal replacements.

## Junctions, attachments, and reshapes

- Attach a generated part to a sculpted stub by tapering the stub about the limb
  axis and collapsing its tip modestly toward a target inside the new part, then
  match the part's socket to the tapered radius and centre; collapsing to a
  point flares a skirt.
- Replace a mismatched neck junction instead of deforming a closed head: loft
  one sleeve from inside the body into the jaw, wide enough to cover the body's
  open rim and then narrower than the head so its top edge is buried, and check
  that it stays the wider surface until the jaw overtakes it.
- A reshape invalidates everything fitted to the old surface. Transform garments
  the same way, move rigid accessories by object location, and remap hair, head,
  and bones with one function so bind and seams stay intact; shortening a neck
  is not a local edit.
