# Mesh surgery

Closed boundaries, finite normals, manifold topology, normalized weights, and
preserved volume or ring areas do not prove a sound surface or exclude
crossings. Check adjacency, correspondence, and crossings, then inspect renders,
which catch faults the numbers miss.

## Bridge boundaries

- Traverse actual boundary edges and require one simple cycle; sorting vertices
  by angle skips real edges and opens lateral holes.
- Normalize both loops' projected signed orientation before pairing; a local
  next-angle choice fails where a cut perimeter doubles back. A bridge between
  oppositely oriented loops added no boundary edges yet crossed itself over a
  thousand times.
- Pair loops by local landmarks while preserving adjacency. Equal fractions of
  arc length drift between differently shaped loops; after orientation was
  fixed, that drift still left 87 crossings.
- A shared parameter chart makes correspondence valid but cannot smooth jagged
  fixed anchors, which still crease.

## Track identity across operators

`bmesh.ops.subdivide_edges` and similar operators invalidate held `BMVert`
references. Track identity through a custom attribute or saved coordinates, and
verify the intended unchanged region afterwards.

## Cut openings and project onto them

- Classify constrained triangulation output by connected regions that respect
  the constraint edges, not by per-triangle centroids, which misclassify thin
  triangles; verify boundary incidence after selection.
- Sequential half-plane clipping of adjacent triangles leaves collinear
  T-junctions when fragments do not share subdivisions; welding afterwards
  reduces them without removing them.
- A cut on a coarse cage oscillates about the intended curve by about a face
  width; keep a covering piece's edge inside the rim minimum so its own smooth
  edge is the visible boundary.
- Rays cast along a garment opening pass through the hole, and alternating hits
  and misses render as evenly spaced slats that look like a normals fault. Cast
  against the evaluated shell with its armature modifier disabled, falling back
  to the body only where the shell has no surface; a constant body offset fails
  because the garment gap varies.

## Check clearance and intersections

At a tight tube bend, both approaching sides can expand into each other even
when the middle is narrow. Cap the radius across the whole bend and its
approaches, keep smaller existing radii, and choose the largest cap that passes
the limb's geometry and pose checks. Use triangle-intersection checks with
earlier failing cases as positive controls; vertex-distance samples do not
certify triangles or continuous motion.

## Custom solvers

For each Laplacian row, put unknown coefficients in the matrix and only fixed
coordinates in the constant; an unknown centre contributes nothing to the
constant, and a zero residual can come from solving the wrong system. Probe a
new solver with a planar case whose harmonic centre is known and with a
translated input that must translate the solution equally. Reconstruct a saved
result from the same system before interpreting a constraint ablation, and keep
absolute positions, displacements, and fixed support terms distinct; writing
`C*x = 0` where the system needs `C*(x - carrier) = 0` invalidated one ablation.
