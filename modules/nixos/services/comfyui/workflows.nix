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
      Qwen-Image-2512-Lightning-4steps-V1.0-bf16.safetensors

    jq '
      .nodes |= map(select(.type != "MarkdownNote"))
      | .definitions.subgraphs[0].nodes |= map(
          if .id == 229 then .widgets_values[0] = true else . end
        )
    ' text-to-image.json > "$out/01-qwen-image-2512.json"

    jq -e '
      ([.definitions.subgraphs[0].nodes[]
        | select(
            .id == 229
            and .type == "PrimitiveBoolean"
            and .widgets_values[0] == true
          )] | length == 1)
      and ([.. | strings
        | select(. == "qwen_image_2512_fp8_e4m3fn.safetensors")]
        | length > 0)
      and ([.. | strings
        | select(. == "Qwen-Image-2512-Lightning-4steps-V1.0-bf16.safetensors")]
        | length > 0)
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
      and ([.. | strings
        | select(. == "qwen_image_edit_2511_int8_convrot.safetensors")]
        | length > 0)
      and ([.. | strings
        | select(. == "Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors")]
        | length > 0)
    ' "$out/02-qwen-image-edit-2511.json" > /dev/null

    jq '
      .nodes |= map(select(.type != "MarkdownNote"))
      | .nodes |= map(
          if .id == 55 and .type == "Wan22ImageToVideoLatent" then
            .widgets_values = [640, 384, 49, 1]
          elif .id == 58 and .type == "SaveVideo" then
            .widgets_values[0] = "video/Wan2.2-5B"
          else . end
        )
    ' ${videoGeneration} > "$out/03-wan2.2-video.json"

    jq -e '
      ([.nodes[]
        | select(
            .id == 37
            and .type == "UNETLoader"
            and .widgets_values[0] == "wan2.2_ti2v_5B_fp16.safetensors"
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
            and .widgets_values[0] == "wan2.2_vae.safetensors"
          )] | length == 1)
      and ([.nodes[]
        | select(
            .id == 55
            and .type == "Wan22ImageToVideoLatent"
            and .widgets_values == [640, 384, 49, 1]
          )] | length == 1)
      and ([.nodes[]
        | select(.id == 56 and .type == "LoadImage" and .mode == 4)]
        | length == 1)
      and ([.nodes[]
        | select(.id == 3 and .type == "KSampler" and .widgets_values[2] == 20)]
        | length == 1)
      and ([.nodes[]
        | select(.id == 57 and .type == "CreateVideo" and .widgets_values[0] == 24)]
        | length == 1)
      and ([.nodes[]
        | select(
            .id == 58
            and .type == "SaveVideo"
            and .widgets_values[0] == "video/Wan2.2-5B"
          )] | length == 1)
      and ([.nodes[] | select(.type == "MarkdownNote")] | length == 0)
    ' "$out/03-wan2.2-video.json" > /dev/null

    cp ${license} "$out/LICENSE"
  ''
