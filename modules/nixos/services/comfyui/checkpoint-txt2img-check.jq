# Assert the shape checkpoint-txt2img.jq is supposed to produce. Run with jq -e
# and the same $p parameters, so a template revision bump that moves node ids or
# widget layouts fails the build instead of shipping a broken graph.

($p.vae != "") as $externalVae
| ((.links | map(.[0])) as $keptLinks
  | [.nodes[].outputs[].links[] | select(. as $l | $keptLinks | index($l) | not)]
  | length == 0)
and ((.links | map(.[0])) as $keptLinks
  | [.nodes[].inputs[].link
      | select(. != null)
      | select(. as $l | $keptLinks | index($l) | not)]
  | length == 0)

# Duplicate ids make LiteGraph routing ambiguous even when every referenced id
# exists. Reject them before checking individual sockets.
and (([.nodes[].id] | length) == ([.nodes[].id] | unique | length))
and (([.links[] | .[0]] | length) == ([.links[] | .[0]] | unique | length))

# An id that still exists but now points at a different source survives the
# transform's prune, so check each output socket owns the links it lists.
and (. as $graph
  | [.nodes[]
      | . as $n
      | (.outputs // []) | to_entries[] | . as $slot
      | ($slot.value.links // [])[]
      | select(. as $id
          | [$graph.links[]
              | select(.[0] == $id and .[1] == $n.id and .[2] == $slot.key)]
          | length != 1)]
  | length == 0)

# A link whose declared type disagrees with either socket means two inputs got
# swapped. Same-type swaps need explicit routing checks, below.
and (. as $graph
  | [.links[]
      | select(.[5] as $t | .[1] as $src | .[2] as $slot
          | ([$graph.nodes[] | select(.id == $src) | .outputs[$slot].type] | first) != $t)]
  | length == 0)
and (. as $graph
  | [.links[]
      | select(.[5] as $t | .[3] as $dst | .[4] as $slot
          | ([$graph.nodes[] | select(.id == $dst) | .inputs[$slot].type] | first) != $t)]
  | length == 0)

# Positive and negative are both CONDITIONING, so only the slot tells them
# apart. Swapping them produces a valid graph that generates the negative.
and ([.nodes[]
  | select(
      .id == 10
      and (.inputs | map(.name)) == ["model", "positive", "negative", "latent_image"]
    )] | length == 1)
and ([.links[] | select(.[0] == 11 and .[1] == 6 and .[3] == 10 and .[4] == 1)] | length == 1)
and ([.links[] | select(.[0] == 12 and .[1] == 7 and .[3] == 10 and .[4] == 2)] | length == 1)
and ([.nodes[]
  | select(.id == 17 and (.inputs | map(.name)) == ["samples", "vae"])] | length == 1)
and ([.links[] | select(.[0] == 34 and .[3] == 17 and .[4] == 1)] | length == 1)

# litegraph allocates new ids from these, so a stale value collides with the
# injected hires nodes as soon as the user adds a node in the UI.
and (.last_node_id >= ([.nodes[].id] | max))
and (.last_link_id >= ([.links[] | .[0]] | max))

# Every link endpoint resolves to a socket that lists the link back.
and (. as $graph
  | [.links[] | select(
      (.[0] as $id | .[1] as $src | .[2] as $slot
        | [$graph.nodes[] | select(.id == $src) | .outputs[$slot].links[]?
            | select(. == $id)] | length != 1)
    )] | length == 0)
and (. as $graph
  | [.links[] | select(
      (.[0] as $id | .[3] as $dst | .[4] as $slot
        | [$graph.nodes[] | select(.id == $dst) | .inputs[$slot].link
            | select(. == $id)] | length != 1)
    )] | length == 0)

and ([.nodes[]
  | select(
      .id == 4
      and .type == "CheckpointLoaderSimple"
      and .widgets_values == [$p.checkpoint]
      and .outputs[2].links == (
        if $externalVae then []
        elif $p.hires != null then [34, 105, 107]
        else [34]
        end
      )
    )] | length == 1)
and ([.nodes[]
  | select(
      .id == 10
      and .type == "KSampler"
      and (.inputs | length) == 4
      and (.inputs | map(has("widget")) | any | not)
      and .outputs[0].links == (if $p.hires != null then [100] else [25] end)
      and .widgets_values == $p.sampler
    )] | length == 1)
and ([.nodes[]
  | select(
      .id == 5
      and .type == "EmptyLatentImage"
      and .title == "Composition Canvas"
      and .widgets_values == $p.latent
    )]
  | length == 1)
and ([.nodes[]
  | select(.id == 19 and .type == "SaveImage" and .widgets_values[0] == $p.prefix)]
  | length == 1)

# Nodes 50 and 51 are PrimitiveNodes wired into the text widgets of 6 and 7.
# The primitive overwrites the encode node at prompt time, so it is the value
# that actually reaches the sampler and has to be checked too.
and ([.nodes[]
  | select(
      .id == 6 and .type == "CLIPTextEncode" and .widgets_values[0] == $p.positive
    )] | length == 1)
and ([.nodes[]
  | select(
      .id == 7 and .type == "CLIPTextEncode" and .widgets_values[0] == $p.negative
    )] | length == 1)
and ([.nodes[] | select(.id == 51 and .widgets_values[0] == $p.positive)] | length == 1)
and ([.nodes[] | select(.id == 50 and .widgets_values[0] == $p.negative)] | length == 1)

and ([.nodes[]
  | select(.id as $id | [11, 15, 16, 45, 47] | index($id))] | length == 0)
and ([.nodes[] | select(.type == "Note" or .type == "MarkdownNote")] | length == 0)
and ([.nodes[] | select(.properties.models?)] | length == 0)

and (if $p.hires != null then
    ($p.hires.upscaleModelScale > 0)
    and ($p.hires.finalScale > 0)
    and (($p.hires.finalScale / $p.hires.upscaleModelScale) >= 0.01)
    and (($p.hires.finalScale / $p.hires.upscaleModelScale) <= 8)
    and
    ([.nodes[]
      | select(
          .id == 60
          and .type == "ImageScaleBy"
          and (.inputs | map(.name)) == ["image"]
          and .title == "Final \($p.hires.finalScale)x Composition"
          and .widgets_values
            == ["lanczos", ($p.hires.finalScale / $p.hires.upscaleModelScale)]
        )] | length == 1)
    and ([.nodes[]
      | select(
          .id == 64
          and .type == "UpscaleModelLoader"
          and .widgets_values == [$p.hires.upscaleModel]
        )] | length == 1)
    and ([.nodes[]
      | select(
          .id == 65
          and .type == "ImageUpscaleWithModel"
          and (.inputs | map(.name)) == ["upscale_model", "image"]
        )] | length == 1)
    and ([.nodes[]
      | select(.id == 62 and .type == "VAEDecode")] | length == 1)
    and ([.nodes[]
      | select(.id == 63 and .type == "VAEEncode")] | length == 1)
    and ([.nodes[]
      | select(
          .id == 61
          and .type == "KSampler"
          and .widgets_values == $p.hires.sampler
          and (.inputs | map(.name)) == ["model", "positive", "negative", "latent_image"]
        )] | length == 1)
    and ([.links[]
      | select(.[0] == 25 and .[1] == 61 and .[2] == 0 and .[3] == 17)] | length == 1)
    and ([.links[]
      | select(.[0] == 100 and .[1] == 10 and .[2] == 0 and .[3] == 62)] | length == 1)
    and ([.links[]
      | select(.[0] == 108 and .[1] == 63 and .[2] == 0 and .[3] == 61 and .[4] == 3)]
      | length == 1)
    and ([.links[]
      | select(.[0] == 103 and .[1] == 6 and .[3] == 61 and .[4] == 1)] | length == 1)
    and ([.links[]
      | select(.[0] == 104 and .[1] == 7 and .[3] == 61 and .[4] == 2)] | length == 1)
    and ([.links[]
      | select(.[0] == 101 and .[1] == 62 and .[2] == 0 and .[3] == 65 and .[4] == 1)]
      | length == 1)
    and ([.links[]
      | select(.[0] == 109 and .[1] == 64 and .[2] == 0 and .[3] == 65 and .[4] == 0)]
      | length == 1)
    and ([.links[]
      | select(.[0] == 110 and .[1] == 65 and .[2] == 0 and .[3] == 60 and .[4] == 0)]
      | length == 1)
    and ([.links[]
      | select(.[0] == 106 and .[1] == 60 and .[2] == 0 and .[3] == 63 and .[4] == 0)]
      | length == 1)
  else
    ([.nodes[] | select(.id as $i | [60, 61, 62, 63, 64, 65] | index($i))] | length == 0)
    and ([.links[]
      | select(.[0] == 25 and .[1] == 10 and .[2] == 0 and .[3] == 17)] | length == 1)
  end)

and (if $externalVae then
    ([.nodes[]
      | select(.id == 12 and .type == "VAELoader" and .widgets_values == [$p.vae])]
      | length == 1)
    and ([.links[]
      | select(.[0] == 34 and .[1] == 12 and .[2] == 0 and .[3] == 17)] | length == 1)
  else
    ([.nodes[] | select(.id == 12)] | length == 0)
    and ([.links[]
      | select(.[0] == 34 and .[1] == 4 and .[2] == 2 and .[3] == 17)] | length == 1)
  end)
