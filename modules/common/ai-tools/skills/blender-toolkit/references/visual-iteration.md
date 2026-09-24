# Artwork-driven visual iteration

For small live tweaks, edit the open model with specialized MCP operations where
available, otherwise short `bpy` commands scoped to the named region. Do not
substitute a whole-model generator, or rebuild unrelated geometry to keep a
script as the source of truth.

## Choose the inspection render

- **Form:** judge a Workbench clay render (`STUDIO` light, `SINGLE` color,
  cavity type `BOTH`, shadows, `Standard` view transform) as a fixed multi-angle
  sheet, since one view hides asymmetry and depth, and restore the presentation
  settings afterwards. Soft-lit skin under AgX hides form; a featureless paddle
  passed as a hand through several such reviews.
- **Likeness:** judge a flat-color render under soft neutral light, painted with
  the reference's identity cues: hair mass, iris and brow darkness, lip tint,
  skin warmth, and expression. A bald clay head is unrecognizable however
  accurate its form. Judging paint is an aid; the runtime still needs a real
  texture or vertex colors.

Rule out shading before blaming form. Zero subsurface weight reads as plastic.
AgX desaturates, so compare median colors sampled from matching render and
reference regions rather than swatches. A linked Base Color ignores the BSDF
socket value; edit the node that feeds it.

## Get a reference that can show the edit

Reference resolution bounds the smallest judgeable edit: a head about 50 px tall
on a 16-figure board could not show sub-millimetre changes, and a single-subject
sheet raised it to about 400 px at the same image size. Before detailed work,
ask for one subject per sheet, with orthographic front, side, and back views at
one scale and pose, guides through landmarks such as crown and chin, directions
labelled from the subject's perspective, and a flat-color view without cast
shadows.

Generated sheets are proposals, not calibrated projections. Check each profile's
facing from an asymmetric detail such as a pocket or hair part; one image model
drew most profiles facing one way until each got its own sheet with the facing
in the prompt. Check printed guides against the drawing, and whether a slight
turn toward the viewer explains a small profile offset. Compare landmarks across
views before tracing; when they disagree, as when a profile put the ear top
about 12 mm above the front view, follow one view and record which.

Reference pixels are lit illustration, not albedo; correct sampled colors
against the render. Read openings such as a collar V from skin pixels, since
piping and silhouette edges are also dark, and measure lashes, lids, and iris on
a ruled close-up, since a dark threshold merges them.

## Register the comparison

Register orthographic cameras on a landmark pair the reference shows, such as
pupil separation, a drawn chin, or a bald crown on its guide, and confirm with
an independent landmark, such as the eye line on the drawn pupils. A crown under
hair is only an estimate; moving one shifted a measured eye-height gap from 15.5
mm to about 5 mm. Pin the camera numerically and render in the panel's pixel
window so guides overlay; a bounding-box camera rescales as the sculpt changes.

Composite the panel beside each render at matched scale and landmark crop, with
a 50 percent blend overlay per feature so offsets show directly. Keep camera,
lighting, exposure, material, and color-management setup in one script shared by
live and headless renders, write live tweaks back into it, and hold setup and
pose fixed across a correction. Use neutral light that keeps light-fabric
detail, add a strip showing the model at the size the runtime camera renders it,
and keep rig overlays out of appearance reviews.

These registration errors reversed verdicts:

- a crop that cuts the head or figure pins its silhouette to the crop edge;
- an illustrated profile draws the cornea, one eyeball radius ahead of the
  eyeball centre, so register profiles on the cornea;
- a bald model against a haired outline misreads skull size until a closed hair
  block-in exists or the reference shows the hairline;
- sizing heads by figure height blames the head for a body proportion;
- a front render's apparent face edge can be a shading terminator.

## Correct from large to small

Fix what a viewer notices first and leave surface form for last. The head pass
the user judged a clear improvement went hair mass, then nose, ear, and jaw
placement, then eye size, spacing, iris, lids, and brows, with expression still
open. Move whole features by the distance the comparison shows; that pass moved
them 5 to 30 mm at a time, after four rounds of sub-millimetre falloff nudges
had passed every self-check without resemblance. Falloffs fix local relief, not
styling or proportion. Move coupled parts together, such as an eyeball with its
lids and socket, and report every edit outside the named feature.

## One correction per inspection

1. Name the largest visible mismatch and the observation that would show it
   fixed in the affected view and pose, such as a continuous hem where a
   waistband poked through. Separate inherited body or head defects from garment
   faults, and verify any fault inherited from notes, packets, or earlier rounds
   by looking or measuring; crops, hair, and misattributed ownership made such
   premises repeatedly wrong.
2. Save each step as its own `.blend` beside its edit list; renders alone cannot
   restore the good state before a rejected endpoint. Edit in place and preserve
   accepted regions. Rebuild only when the construction itself failed, say why,
   and compare preserved regions afterwards; a generator run from an older
   checkpoint must not discard accepted edits.
3. Inspect the cheapest evidence that settles the hypothesis, such as a black
   texture's pixels and reloaded image before a character render, or evaluated
   surfaces in the failing pose before adding folds. Surface noise cannot fix
   silhouette or missing garment construction.
4. Inspect one useful view, crop, or fixed multi-angle sheet beside the
   reference and previous checkpoint, and state improved, unchanged, or
   regressed with the visible reason. Keep only supported corrections, and do
   not launch another batch to postpone judgment. If a step reads unchanged,
   confirm it landed: measure the region, reload edited helper modules, and
   check that falloffs reach full weight.
5. Expand to other views and motion only after the local correction holds. If a
   mismatch survives the task's retry limit, change the construction method or
   seek a bounded review; renaming a checkpoint does not reset a failed method.

## Let the user judge likeness

The author's self-check is not an acceptance gate. Comparing the whole subject
with the reference and round start every few kept steps catches drift into
caricature, which accumulates through per-fault "improved" verdicts, but it does
not establish likeness: across four heads, 23 whole-face checks never vetoed a
step while the user saw no resemblance.

Fix obvious side-by-side mismatches directly and show before and after; the user
redirected a variant round to nose, ear, and neck faults visible at a glance.
Reserve variants for open style or identity choices: put three or four clearly
different options on one labelled sheet with the target panel, in front and
profile rows at matched height, and ask one short question, such as which hair
volume is closest, or none. Branch from the pick; if the answer is none, change
the approach instead of shrinking the step. Keep saved renders in a strip so a
drifting run shows where it turned.

## Measure to locate, not to optimize

Numbers catch nonsense and locate discrepancies; the image decides. A ratio exit
criterion turned a cast into scaled copies of one face, and minimizing a
silhouette-width error gave a lumpier body that the user rejected on sight. To
test a proportion judged by eye, compare per-row extents from the panel and a
`film_transparent` render, normalized to figure or head height; that traced a
"stocky toddler" read to arm standoff and narrow trousers and feet. Outlines
merge arms into width and cannot show whether a surface reads as a body.

## Detail and acceptance

After silhouette, garment construction, and deformation hold, match material
identity: pattern scale and direction, fabric color, collar, placket, and pocket
thickness, seams, piping, folds, roughness, and visible weave. Add only details
the reference supports, and bake procedural detail the runtime importer needs.
Plan whole-character work at about one corrected property per build, render, and
inspect iteration.

For delegated work, the author inspects images before handoff, and the
coordinator judges separately at meaningful checkpoints, not every vertex edit.
Report target, before and after, remaining gaps, and acceptance state; never
call a structurally valid or merely saved checkpoint "final" while visual gaps
remain. Source approval is not game completion: inspect the clean-imported
candidate and the production-selected model, materials, and animations in
gameplay, and keep rejected drafts out of runtime assets.
