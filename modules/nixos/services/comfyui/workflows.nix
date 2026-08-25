{
  fetchurl,
  jq,
  lib,
  runCommand,
}:
let
  revision = "42967c1912f5ec6c85ac2f6e4a86c5a0b1822e12";
  baseUrl = "https://raw.githubusercontent.com/Comfy-Org/workflow_templates/${revision}";

  textToImage = fetchurl {
    url = "${baseUrl}/templates/image_qwen_Image_2512.json";
    hash = "sha256-BqpEiqSXrXGfRwmtz5WRbirs4TTM4yIVVHbDqUAVycw=";
    meta.license = lib.licenses.mit;
  };

  imageEdit = fetchurl {
    url = "${baseUrl}/templates/image_qwen_image_edit_2511_int8.json";
    hash = "sha256-9pFT2Fej5603TEt5d1+i2NmTYRNYBqXs9xBvLkHNIzY=";
    meta.license = lib.licenses.mit;
  };

  videoGeneration = fetchurl {
    url = "${baseUrl}/templates/video_wan2_2_5B_ti2v.json";
    hash = "sha256-UDkHmKEzdXB111CreLJidOO/PkoJ9GqqLwjZVZ5idQs=";
    meta.license = lib.licenses.mit;
  };

  license = fetchurl {
    url = "${baseUrl}/LICENSE";
    hash = "sha256-XczWHIDIR81rIvqYEkAQFjq4ZG5XNVehalyuMRIvIFY=";
  };
in
runCommand "comfyui-khanelinix-workflows"
  {
    nativeBuildInputs = [ jq ];
  }
  ''
    mkdir -p "$out"

    cp ${textToImage} text-to-image.json
    substituteInPlace text-to-image.json \
      --replace-fail \
      Qwen-Image-2512-Lightning-4steps-V1.0-fp32.safetensors \
      Qwen-Image-2512-Lightning-4steps-V1.0-bf16.safetensors \
      --replace-fail \
      qwen_image_2512_fp8_e4m3fn.safetensors \
      Qwen-Image-2512-Q5_K_S-5.10bpw.gguf

    jq '
      .nodes |= map(select(.type != "MarkdownNote"))
      | .definitions.subgraphs[0].nodes |= map(
          if .id == 226 and .type == "UNETLoader" then
            .type = "UnetLoaderGGUF"
            | .widgets_values = ["Qwen-Image-2512-Q5_K_S-5.10bpw.gguf"]
            | .properties["Node name for S&R"] = "UnetLoaderGGUF"
          elif .id == 224 and .type == "PrimitiveInt" then
            .widgets_values = [20, "fixed"]
          elif .id == 229 and .type == "PrimitiveBoolean" then
            .widgets_values[0] = false
          elif .id == 232 and .type == "EmptySD3LatentImage" then
            .widgets_values = [1024, 1024, 1]
          else . end
        )
    ' text-to-image.json > "$out/01-qwen-image-2512.json"

    jq -e '
      ([.definitions.subgraphs[0].nodes[]
        | select(
            .id == 229
            and .type == "PrimitiveBoolean"
            and .widgets_values[0] == false
          )] | length == 1)
      and ([.definitions.subgraphs[0].nodes[]
        | select(
            .id == 226
            and .type == "UnetLoaderGGUF"
            and .widgets_values == ["Qwen-Image-2512-Q5_K_S-5.10bpw.gguf"]
          )] | length == 1)
      and ([.definitions.subgraphs[0].nodes[]
        | select(
            .id == 219
            and .type == "CLIPLoader"
            and .widgets_values[0] == "qwen_2.5_vl_7b_fp8_scaled.safetensors"
          )] | length == 1)
      and ([.definitions.subgraphs[0].nodes[]
        | select(.id == 224 and .widgets_values == [20, "fixed"])]
        | length == 1)
      and ([.definitions.subgraphs[0].nodes[]
        | select(.id == 232 and .widgets_values == [1024, 1024, 1])]
        | length == 1)
      and ([.definitions.subgraphs[0].nodes[]
        | select(
            .id == 221
            and .type == "LoraLoaderModelOnly"
            and .widgets_values[0] == "Qwen-Image-2512-Lightning-4steps-V1.0-bf16.safetensors"
          )] | length == 1)
    ' "$out/01-qwen-image-2512.json" > /dev/null

    jq '
      .nodes |= map(select(.type != "MarkdownNote"))
      | .definitions.subgraphs[0].nodes |= map(
          if .id == 168 then .widgets_values[0] = true else . end
        )
    ' ${imageEdit} > "$out/02-qwen-image-edit-2511.json"

    jq -e '
      ([.definitions.subgraphs[0].nodes[]
        | select(
            .id == 168
            and .type == "PrimitiveBoolean"
            and .widgets_values[0] == true
          )] | length == 1)
      and ([.definitions.subgraphs[0].nodes[]
        | select(
            .id == 161
            and .type == "UNETLoader"
            and .widgets_values[0] == "qwen_image_edit_2511_int8_convrot.safetensors"
          )] | length == 1)
      and ([.definitions.subgraphs[0].nodes[]
        | select(
            .id == 153
            and .type == "LoraLoaderModelOnly"
            and .widgets_values[0] == "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"
          )] | length == 1)
    ' "$out/02-qwen-image-edit-2511.json" > /dev/null

    jq '
      .nodes |= map(select(.type != "MarkdownNote" and .id != 56))
      | .links |= map(select(.[0] != 105 and .[0] != 106))
      | .groups |= map(select(.id != 3))
      | .nodes |= map(
          del(.properties.models)
          | if .id == 37 and .type == "UNETLoader" then
            .widgets_values[0] = "wan2.1_t2v_1.3B_fp16.safetensors"
          elif .id == 39 and .type == "VAELoader" then
            .widgets_values[0] = "wan_2.1_vae.safetensors"
          elif .id == 55 and .type == "Wan22ImageToVideoLatent" then
            .type = "EmptyHunyuanLatentVideo"
            | .inputs = []
            | .properties."Node name for S&R" = "EmptyHunyuanLatentVideo"
            | .widgets_values = [640, 384, 17, 1]
          elif .id == 57 and .type == "CreateVideo" then
            .widgets_values[0] = 16
          elif .id == 58 and .type == "SaveVideo" then
            .widgets_values[0] = "video/Wan2.1-1.3B"
          elif .id == 6 and .type == "CLIPTextEncode" then
            .widgets_values[0] = "A red fox runs through a snowy forest, cinematic tracking shot, detailed fur, natural motion"
          else . end
        )
    ' ${videoGeneration} > "$out/03-wan2.1-video.json"

    jq -e '
      ([.nodes[]
        | select(
            .id == 37
            and .type == "UNETLoader"
            and .widgets_values[0] == "wan2.1_t2v_1.3B_fp16.safetensors"
          )] | length == 1)
      and ([.nodes[]
        | select(
            .id == 38
            and .type == "CLIPLoader"
            and .widgets_values[0] == "umt5_xxl_fp8_e4m3fn_scaled.safetensors"
          )] | length == 1)
      and ([.nodes[]
        | select(
            .id == 39
            and .type == "VAELoader"
            and .widgets_values[0] == "wan_2.1_vae.safetensors"
          )] | length == 1)
      and ([.nodes[]
        | select(
            .id == 55
            and .type == "EmptyHunyuanLatentVideo"
            and .inputs == []
            and .widgets_values == [640, 384, 17, 1]
          )] | length == 1)
      and ([.nodes[] | select(.id == 56)] | length == 0)
      and ([.links[] | select(.[0] == 105 or .[0] == 106)] | length == 0)
      and ([.nodes[]
        | select(.id == 3 and .type == "KSampler" and .widgets_values[2] == 20)]
        | length == 1)
      and ([.nodes[]
        | select(.id == 57 and .type == "CreateVideo" and .widgets_values[0] == 16)]
        | length == 1)
      and ([.nodes[]
        | select(
            .id == 58
            and .type == "SaveVideo"
            and .widgets_values[0] == "video/Wan2.1-1.3B"
          )] | length == 1)
      and ([.nodes[]
        | select(
            .id == 6
            and .type == "CLIPTextEncode"
            and (.widgets_values[0] | startswith("A red fox runs"))
          )] | length == 1)
      and ([.nodes[] | select(.type == "MarkdownNote")] | length == 0)
      and ([.nodes[] | select(.properties.models?)] | length == 0)
    ' "$out/03-wan2.1-video.json" > /dev/null

    cp ${license} "$out/LICENSE"
  ''
