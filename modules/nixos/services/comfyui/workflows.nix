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

    cp ${license} "$out/LICENSE"
  ''
