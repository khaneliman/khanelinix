# Artwork-driven visual iteration

Use this loop when matching concept art or correcting a visibly weak asset. MCP
is the control channel, not a modeling method or an artistic quality check.
Python through MCP is appropriate for local edits, inspection, repeatable
construction, and export. Choose direct topology, sculpting, procedural work, or
a hybrid according to the visible correction; do not mistake code volume or a
successful generator run for progress toward the artwork.

When the user requests small live MCP tweaks, keep the open model as the working
asset. Use specialized MCP operations where available; otherwise send short
`bpy` commands scoped to the named region. Do not turn that request into an
external whole-model generator invoked through MCP. Retain a small edit recipe
when reproducibility helps; do not rebuild unrelated geometry merely to keep a
script as the source of truth.

## Set up a comparable view

Identify the authorized artwork panel and current source checkpoint. Keep the
reference and model visible together at comparable scale and view angle. A
full-body view establishes silhouette; a crop establishes garment construction
or surface detail. Label inferred camera/proportion choices. Conflicting concept
views are not measured anatomy or a reason to invent exact dimensions.

Use neutral lighting that retains light-fabric detail. Establish the review
camera, pose, lighting, exposure, and color management, then hold them fixed
across the correction. Keep rig overlays out of appearance reviews. Solid
shading is useful for form, but cannot establish textured appearance. Verify the
live file, visible objects, active material output, and image before attributing
a screenshot defect to geometry.

## One correction per inspection

1. Name the largest visible mismatch and the observation that would show it
   improved. For example: a trouser waistband protrudes through the shirt;
   correction succeeds when the hem remains continuous in the affected view and
   pose. Separate inherited body/head defects from a garment assignment.
2. Checkpoint the current scene without overwriting the recovery source.
   Preserve accepted regions. Edit the relevant objects, vertices, UVs, or
   material in place. Rebuild the whole asset only when the failed construction
   requires it; identify why and compare preserved regions afterward. A
   generator starting from an older checkpoint must not discard accepted edits.
3. Inspect the cheapest evidence that settles the hypothesis. For a black
   texture, inspect its pixels and the saved/reloaded image before rendering the
   character. For garment overlap, inspect evaluated surfaces in the failing
   pose before adding folds. A surface noise node cannot fix silhouette or
   missing garment construction.
4. Capture one useful view or crop and actually inspect it beside the reference
   and preceding checkpoint. State improved, unchanged, or regressed, with the
   visible reason. Retain a correction only when its effect is supported by that
   comparison. Do not launch another multi-view batch to postpone judgment.
5. Expand to the other views and affected motion only after the local correction
   holds. If the same mismatch survives repeated attempts, follow the task's
   retry limit and change the construction method or seek a bounded review.
   Renaming a checkpoint does not reset a failed method.

## Detail and acceptance

Resolve silhouette, garment construction, and deformation before microdetail.
Then compare material identity: pattern scale and direction across panels,
fabric color, collar/placket/pocket thickness, seams and piping, fold placement,
roughness, and weave where visible. Add the details the reference supports, not
indiscriminate noise. Preserve a bake or supported representation for procedural
detail needed by the runtime importer.

For delegated work, the author inspects the images before handing them to the
coordinator. The coordinator makes a separate visual judgment at a meaningful
checkpoint, not after every vertex edit. Keep the evidence small: target,
before/after, remaining visible gaps, and acceptance state. Do not label a
structurally valid or merely saved checkpoint "final" while visual gaps remain.

Source approval is not game completion. For game-facing work, inspect the
clean-imported candidate and the actual production-selected model, materials,
and animations in gameplay. Keep rejected drafts out of runtime assets.
