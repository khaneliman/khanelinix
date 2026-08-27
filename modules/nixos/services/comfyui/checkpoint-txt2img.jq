# Reduce the upstream SDXL base-plus-refiner template to a single-checkpoint
# text-to-image graph. $p carries the per-workflow parameters:
#
#   checkpoint      file name the CheckpointLoaderSimple node loads
#   checkpointTitle title shown on that loader node
#   vae             VAELoader file name, or "" to decode with the checkpoint VAE
#   positive        positive prompt text
#   negative        negative prompt text
#   prefix          SaveImage filename prefix
#   latent          EmptyLatentImage widget values [width, height, batch]
#   sampler         KSampler widget values
#   hires           null, or {
#                     finalScale, upscaleModel, upscaleModelScale, sampler
#                   }
#
# Node 12 is the refiner checkpoint loader. It becomes the VAELoader when $p.vae
# is set, which keeps link 34 pointed at a real VAE source either way.

[11, 15, 16, 45, 47] as $refinerNodes
| [13, 14, 19, 20, 23, 24, 38, 41, 43, 44, 47, 48] as $refinerLinks
| ($p.vae != "") as $externalVae

# Drop the refiner half and the tutorial annotations.
| .nodes |= map(select(
    (.type != "Note" and .type != "MarkdownNote")
    and (.id as $id | $refinerNodes | index($id) | not)
    and (.id != 12 or $externalVae)
  ))
| .links |= map(select(.[0] as $id | $refinerLinks | index($id) | not))
| .groups |= map(select(
    .id != 2
    and .id != 8
    and .id != 12
    and (.id != 5 or $externalVae)
  ))
| .groups |= map(
    if .id == 1 then .title = "Prompt Encoding"
    elif .id == 4 then .title = "Load Checkpoint"
    elif .id == 5 then .title = "Load VAE"
    elif .id == 11 then .title = "Sampler"
    else . end
  )

# Sampling now ends at the base pass, and the VAE comes from whichever loader
# survived above.
| .links |= map(
    if .[0] == 25 then [.[0], 10, 0, .[3], .[4], .[5]]
    elif .[0] == 34 then
      (if $externalVae then [.[0], 12, 0, .[3], .[4], .[5]]
       else [.[0], 4, 2, .[3], .[4], .[5]] end)
    else . end
  )

| .nodes |= map(
    if .id == 4 and .type == "CheckpointLoaderSimple" then
      del(.properties.models)
      | .title = $p.checkpointTitle
      | .widgets_values = [$p.checkpoint]
      | .outputs[2].links = (if $externalVae then [] else [34] end)
    elif .id == 12 then
      del(.properties.models)
      | .type = "VAELoader"
      | .title = "Load VAE"
      | .size = [350, 60]
      | .properties["Node name for S&R"] = "VAELoader"
      | .inputs = []
      | .outputs = [{ "name": "VAE", "type": "VAE", "slot_index": 0, "links": [34] }]
      | .widgets_values = [$p.vae]
    elif .id == 10 and .type == "KSamplerAdvanced" then
      .type = "KSampler"
      | .title = "KSampler"
      | .properties["Node name for S&R"] = "KSampler"
      | .inputs |= map(select(has("widget") | not))
      | .outputs[0].links = [25]
      | .widgets_values = $p.sampler
    elif .id == 5 and .type == "EmptyLatentImage" then
      .title = "Composition Canvas"
      | .widgets_values = $p.latent
    elif .id == 6 or .id == 51 then
      .widgets_values[0] = $p.positive
    elif .id == 7 or .id == 50 then
      .widgets_values[0] = $p.negative
    elif .id == 19 and .type == "SaveImage" then
      .widgets_values[0] = $p.prefix
    else . end
  )

# Optional Hires.Fix pass. Composing at the checkpoint's native resolution and
# upscaling at low denoise is what stops duplicated limbs and torsos; both model
# cards call for it. The upscale runs in pixel space because both cards pair
# their low denoise figures with a learned upscaler. Upscaling the latent instead
# leaves 8-pixel stair steps along edges that 0.3 denoise cannot dissolve, and
# ComfyUI's lanczos path quantises to 8-bit before resizing (comfy/utils.py).
# The model upscales 2x, then ImageScaleBy reduces that result to the selected
# 1.5x final scale. The final size therefore follows the editable base canvas
# without a second width and height pair drifting out of sync.
# Ids 60-65 and 100-110 sit above the template's own.
| (if $p.hires != null then
    (if $externalVae then 12 else 4 end) as $vaeNode
    | (if $externalVae then 0 else 2 end) as $vaeSlot
    | ($p.hires.finalScale / $p.hires.upscaleModelScale) as $resizeScale
    | .last_node_id = 65
    | .last_link_id = 110
    | .links |= map(if .[0] == 25 then [.[0], 61, 0, .[3], .[4], .[5]] else . end)
    | .links += [
        [100, 10, 0, 62, 0, "LATENT"],
        [105, $vaeNode, $vaeSlot, 62, 1, "VAE"],
        [101, 62, 0, 65, 1, "IMAGE"],
        [109, 64, 0, 65, 0, "UPSCALE_MODEL"],
        [110, 65, 0, 60, 0, "IMAGE"],
        [106, 60, 0, 63, 0, "IMAGE"],
        [107, $vaeNode, $vaeSlot, 63, 1, "VAE"],
        [108, 63, 0, 61, 3, "LATENT"],
        [102, 4, 0, 61, 0, "MODEL"],
        [103, 6, 0, 61, 1, "CONDITIONING"],
        [104, 7, 0, 61, 2, "CONDITIONING"]
      ]
    | .nodes |= map(
        if .id == 4 then
          .outputs[0].links = [10, 102]
          | (if $externalVae then . else .outputs[2].links = [34, 105, 107] end)
        elif .id == 12 then .outputs[0].links = [34, 105, 107]
        elif .id == 10 then .outputs[0].links = [100]
        elif .id == 6 then .outputs[0].links = [11, 103]
        elif .id == 7 then .outputs[0].links = [12, 104]
        else . end
      )
    | .nodes += [
        {
          "id": 62,
          "type": "VAEDecode",
          "pos": [1160, -160],
          "size": [200, 50],
          "flags": {},
          "order": 23,
          "mode": 0,
          "inputs": [
            { "name": "samples", "type": "LATENT", "link": 100 },
            { "name": "vae", "type": "VAE", "link": 105 }
          ],
          "outputs": [
            { "name": "IMAGE", "type": "IMAGE", "slot_index": 0, "links": [101] }
          ],
          "title": "Decode for Hires",
          "properties": { "Node name for S&R": "VAEDecode" },
          "widgets_values": []
        },
        {
          "id": 64,
          "type": "UpscaleModelLoader",
          "pos": [810, -160],
          "size": [350, 60],
          "flags": {},
          "order": 22,
          "mode": 0,
          "inputs": [],
          "outputs": [
            {
              "name": "UPSCALE_MODEL",
              "type": "UPSCALE_MODEL",
              "slot_index": 0,
              "links": [109]
            }
          ],
          "title": "Load Upscale Model",
          "properties": { "Node name for S&R": "UpscaleModelLoader" },
          "widgets_values": [$p.hires.upscaleModel]
        },
        {
          "id": 65,
          "type": "ImageUpscaleWithModel",
          "pos": [1160, -60],
          "size": [300, 60],
          "flags": {},
          "order": 24,
          "mode": 0,
          "inputs": [
            { "name": "upscale_model", "type": "UPSCALE_MODEL", "link": 109 },
            { "name": "image", "type": "IMAGE", "link": 101 }
          ],
          "outputs": [
            { "name": "IMAGE", "type": "IMAGE", "slot_index": 0, "links": [110] }
          ],
          "title": "Hires Upscale",
          "properties": { "Node name for S&R": "ImageUpscaleWithModel" },
          "widgets_values": []
        },
        {
          "id": 60,
          "type": "ImageScaleBy",
          "pos": [1160, 20],
          "size": [300, 100],
          "flags": {},
          "order": 25,
          "mode": 0,
          "inputs": [{ "name": "image", "type": "IMAGE", "link": 110 }],
          "outputs": [
            { "name": "IMAGE", "type": "IMAGE", "slot_index": 0, "links": [106] }
          ],
          "title": "Final \($p.hires.finalScale)x Composition",
          "properties": { "Node name for S&R": "ImageScaleBy" },
          "widgets_values": [
            "lanczos",
            $resizeScale
          ]
        },
        {
          "id": 63,
          "type": "VAEEncode",
          "pos": [1160, 60],
          "size": [200, 50],
          "flags": {},
          "order": 26,
          "mode": 0,
          "inputs": [
            { "name": "pixels", "type": "IMAGE", "link": 106 },
            { "name": "vae", "type": "VAE", "link": 107 }
          ],
          "outputs": [
            { "name": "LATENT", "type": "LATENT", "slot_index": 0, "links": [108] }
          ],
          "title": "Encode for Hires",
          "properties": { "Node name for S&R": "VAEEncode" },
          "widgets_values": []
        },
        {
          "id": 61,
          "type": "KSampler",
          "pos": [1160, 160],
          "size": [300, 262],
          "flags": {},
          "order": 27,
          "mode": 0,
          "inputs": [
            { "name": "model", "type": "MODEL", "link": 102 },
            { "name": "positive", "type": "CONDITIONING", "link": 103 },
            { "name": "negative", "type": "CONDITIONING", "link": 104 },
            { "name": "latent_image", "type": "LATENT", "link": 108 }
          ],
          "outputs": [
            { "name": "LATENT", "type": "LATENT", "slot_index": 0, "links": [25] }
          ],
          "title": "KSampler - Hires Pass",
          "properties": { "Node name for S&R": "KSampler" },
          "widgets_values": $p.hires.sampler
        }
      ]
  else . end)

# Removing nodes leaves stale link ids on the surviving output sockets.
| (.links | map(.[0])) as $keptLinks
| .nodes |= map(
    .outputs |= map(.links |= map(select(. as $l | $keptLinks | index($l))))
  )
