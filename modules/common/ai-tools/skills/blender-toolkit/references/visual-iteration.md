# Artwork-driven visual iteration

For small live tweaks, edit the open model with specialized MCP operations where
available, otherwise short `bpy` commands scoped to the named region. Do not
substitute a whole-model generator, or rebuild unrelated geometry to keep a
script as the source of truth.

Read [historical evidence](visual-iteration-evidence.md) only when a measurement
limit, registration error, or failed acceptance method needs the original
examples and figures. Those examples do not set edit sizes for a new asset.

## Choose the inspection render

- **Form:** judge a Workbench clay render (`STUDIO` light, `SINGLE` color,
  cavity type `BOTH`, shadows, `Standard` view transform) as a fixed multi-angle
  sheet, since one view hides asymmetry and depth, and restore the presentation
  settings afterwards. Soft-lit skin under AgX can hide form defects.
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

Reference resolution bounds the smallest judgeable edit. Before detailed work,
ask for one subject per sheet, with orthographic front, side, and back views at
one scale and pose, guides through landmarks such as crown and chin, directions
labelled from the subject's perspective, and a flat-color view without cast
shadows.

Generated sheets are proposals, not calibrated projections. Check each profile's
facing from an asymmetric detail such as a pocket or hair part. If facing is
wrong, request separate sheets with the facing explicit in each prompt. Check
printed guides against the drawing, and whether a slight turn toward the viewer
explains a small profile offset. Compare landmarks across views before tracing;
when they disagree, follow one view and record which.

Reference pixels are lit illustration, not albedo; correct sampled colors
against the render. Read openings such as a collar V from skin pixels, since
piping and silhouette edges are also dark, and measure lashes, lids, and iris on
a ruled close-up, since a dark threshold merges them.

## Register the comparison

Register orthographic cameras on a landmark pair the reference shows, such as
pupil separation, a drawn chin, or a bald crown on its guide, and confirm with
an independent landmark, such as the eye line on the drawn pupils. A crown under
hair is only an estimate and can change the apparent landmark gap. Pin the
camera numerically and render in the panel's pixel window so guides overlay; a
bounding-box camera rescales as the sculpt changes.

Composite the panel beside each render at matched scale and landmark crop, with
a 50 percent blend overlay per feature so offsets show directly. Keep camera,
lighting, exposure, material, and color-management setup in one script shared by
live and headless renders, write live tweaks back into it, and hold setup and
pose fixed across a correction. Use neutral light that keeps light-fabric
detail, add a strip showing the model at the size the runtime camera renders it,
and keep rig overlays out of appearance reviews.

Check for registration errors before judging geometry:

- a crop that cuts the head or figure pins its silhouette to the crop edge;
- an illustrated profile draws the cornea, one eyeball radius ahead of the
  eyeball centre, so register profiles on the cornea;
- a bald model against a haired outline misreads skull size until a closed hair
  block-in exists or the reference shows the hairline;
- sizing heads by figure height blames the head for a body proportion;
- a front render's apparent face edge can be a shading terminator.

## Correct from large to small

Fix what a viewer notices first and leave surface form for last. Start with
large masses and feature placement, then refine eyes, lids, brows, and
expression according to the visible mismatch. Move whole features by the
distance the registered comparison supports at the asset's scale, not by a fixed
millimetre rule. Falloffs fix local relief, not styling or proportion. Move
coupled parts together, such as an eyeball with its lids and socket, and report
every edit outside the named feature.

## One correction per inspection

1. Name the largest visible mismatch and the observation that would show it
   fixed in the affected view and pose, such as a continuous hem where a
   waistband poked through. Separate inherited body or head defects from garment
   faults, and verify any fault inherited from notes, packets, or earlier rounds
   by looking or measuring. Check crops, hair, and feature ownership before
   accepting a reported defect.
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

The author's self-check is not an acceptance gate. Compare the whole subject
with the reference and round start every few kept steps to catch drift into
caricature from per-fault "improved" verdicts. Those checks do not establish
likeness; the user judges whether the result resembles the target.

Fix obvious side-by-side mismatches directly and show before and after. Reserve
variants for open style or identity choices: put three or four clearly different
options on one labelled sheet with the target panel, in front and profile rows
at matched height, and ask one short question, such as which hair volume is
closest, or none. Branch from the pick; if the answer is none, change the
approach instead of shrinking the step. Keep saved renders in a strip so a
drifting run shows where it turned.

## Measure to locate, not to optimize

Numbers catch nonsense and locate discrepancies; the image decides. Ratios and
silhouette-width errors are diagnostic aids, not likeness or acceptance gates.
To test a proportion judged by eye, compare per-row extents from the panel and a
`film_transparent` render, normalized to figure or head height. Check arm
standoff, trousers, and feet when those extents explain the visible mismatch.
Outlines merge arms into width and cannot show whether a surface reads as a
body.

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
