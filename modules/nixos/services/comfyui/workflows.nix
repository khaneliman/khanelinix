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

  sdxlCheckpoint = fetchurl {
    url = "${baseUrl}/templates/sdxl_simple_example.json";
    hash = "sha256-fzgl3up6P8SU276IONkjNue7RNn68XkUm3MZMwW2jyQ=";
    meta.license = lib.licenses.mit;
  };

  license = fetchurl {
    url = "${baseUrl}/LICENSE";
    hash = "sha256-XczWHIDIR81rIvqYEkAQFjq4ZG5XNVehalyuMRIvIFY=";
  };
  mkCheckpointWorkflow = name: params: ''
    jq --argjson p ${lib.escapeShellArg (builtins.toJSON params)} \
      --from-file ${./checkpoint-txt2img.jq} \
      ${sdxlCheckpoint} > "$out/${name}"

    jq -e --argjson p ${lib.escapeShellArg (builtins.toJSON params)} \
      --from-file ${./checkpoint-txt2img-check.jq} \
      "$out/${name}" > /dev/null
  '';

  cyberRealisticDefaults = {
    checkpoint = "CyberRealisticXLPlay_V10.0_FP16.safetensors";
    checkpointTitle = "Load Checkpoint - CyberRealistic XL";
    vae = "";
    # Both passes start at the same seed and increment together. Each queue
    # explores a new composition without desynchronizing the hires pass.
    sampler = [
      721897303308196
      "increment"
      30
      4
      "dpmpp_2m_sde"
      "karras"
      1
    ];
    # CyberRealistic v10 examples use a 2x learned pass with 20 hires steps.
    # Scaling the 2x result by 0.75 lands at the selected 1.5x final size while
    # keeping the learned intermediate small enough for the display GPU.
    hires = {
      upscaleModel = "RealESRGAN_x2plus.pth";
      upscaleModelScale = 2;
      finalScale = 1.5;
      sampler = [
        721897303308196
        "increment"
        20
        4
        "dpmpp_2m_sde"
        "karras"
        0.35
      ];
    };
  };

  mkCyberRealisticWorkflow =
    name: profile: mkCheckpointWorkflow name (lib.recursiveUpdate cyberRealisticDefaults profile);

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
      | .nodes |= map(
          if .id == 60 and .type == "SaveImage" then
            .widgets_values[0] = "image/Qwen-Image-2512/Base"
          else . end
        )
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
      and ([.nodes[]
        | select(
            .id == 60
            and .type == "SaveImage"
            and .widgets_values[0] == "image/Qwen-Image-2512/Base"
          )] | length == 1)
    ' "$out/01-qwen-image-2512.json" > /dev/null

    jq '
      .nodes |= map(select(.type != "MarkdownNote"))
      | .nodes |= map(
          if .id == 195 and .type == "SaveImageAdvanced" then
            .widgets_values[0] = "image/Qwen-Image-Edit-2511/Edit"
          else . end
        )
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
      and ([.nodes[]
        | select(
            .id == 195
            and .type == "SaveImageAdvanced"
            and .widgets_values[0] == "image/Qwen-Image-Edit-2511/Edit"
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
            .widgets_values[0] = "video/Wan2.1-1.3B/T2V"
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
            and .widgets_values[0] == "video/Wan2.1-1.3B/T2V"
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

    ${mkCyberRealisticWorkflow "04-sdxl-cyberrealistic-landscape.json" {
      positive = "RAW photo, cinematic landscape photography, a rain-soaked city street at night, wide establishing composition, natural perspective, neon reflections, physically accurate lighting, realistic textures, atmospheric depth, subtle film grain, sharp environmental detail";
      negative = "lowres, blurry, distorted perspective, oversaturated, cartoon, illustration, anime, painting, CGI, 3D render, watermark, text, logo";
      prefix = "image/CyberRealisticXL/Landscape";
      latent = [
        1280
        720
        1
      ];
    }}

    ${mkCyberRealisticWorkflow "04-sdxl-cyberrealistic-portrait.json" {
      positive = "RAW photo, close-up head-and-shoulders portrait of an adult woman, natural skin texture, visible pores and fine facial hair, lifelike eyes, 85mm lens, shallow depth of field, soft window key light, subtle fill light, neutral color grading, sharp focus";
      negative = "lowres, bad anatomy, bad hands, deformed iris, deformed pupils, extra fingers, malformed hands, waxy skin, plastic skin, cartoon, illustration, anime, painting, CGI, 3D render, watermark, text, logo";
      prefix = "image/CyberRealisticXL/Portrait";
      latent = [
        720
        1280
        1
      ];
    }}

    ${mkCyberRealisticWorkflow "04-sdxl-cyberrealistic-product.json" {
      positive = "commercial studio product photography, a premium wristwatch centered on a seamless neutral backdrop, three-quarter view, softbox key light, controlled rim light, realistic metal and glass reflections, accurate geometry, crisp material texture, natural contact shadow, sharp focus";
      negative = "lowres, blurry, distorted geometry, warped edges, asymmetry, duplicate object, floating object, cluttered background, blown highlights, crushed shadows, cartoon, illustration, anime, painting, CGI, 3D render, watermark, text, logo";
      prefix = "image/CyberRealisticXL/Product";
      latent = [
        1024
        1024
        1
      ];
    }}

    ${mkCheckpointWorkflow "05-sd15-realistic-vision.json" {
      checkpoint = "Realistic_Vision_V6.0_NV_B1_fp16.safetensors";
      checkpointTitle = "Load Checkpoint - Realistic Vision V6.0 B1";
      # The checkpoint has a usable baked VAE, but the model card recommends
      # sd-vae-ft-mse instead to clear artifacts.
      vae = "vae-ft-mse-840000-ema-pruned.safetensors";
      # The model card's own prompt template. Deviating from it costs realism.
      positive = "RAW photo, a woman on a rain-soaked city street at night, neon reflections, 8k uhd, dslr, soft lighting, high quality, film grain, Fujifilm XT3";
      negative = "(deformed iris, deformed pupils, semi-realistic, cgi, 3d, render, sketch, cartoon, drawing, anime), text, cropped, out of frame, worst quality, low quality, jpeg artifacts, ugly, duplicate, morbid, mutilated, extra fingers, mutated hands, poorly drawn hands, poorly drawn face, mutation, deformed, blurry, dehydrated, bad anatomy, bad proportions, extra limbs, cloned face, disfigured, gross proportions, malformed limbs, missing arms, missing legs, extra arms, extra legs, fused fingers, too many fingers, long neck";
      prefix = "image/RealisticVision-V6/Photo";
      latent = [
        512
        768
        1
      ];
      sampler = [
        721897303308196
        "increment"
        30
        5
        "dpmpp_sde"
        "karras"
        1
      ];
      # The card lists 768x1024 and up, but qualifies it with "use lower
      # resolution if you get a lot of mutations". Duplicated limbs showed up at
      # 768x1024, so the base pass composes at 512x768 and the 1.5x pass takes
      # it to 768x1152. The card calls Hires.Fix mandatory for half and full
      # body framing. The 2x model keeps the learned intermediate close to the
      # final canvas before the 1.5x resize.
      hires = {
        upscaleModel = "RealESRGAN_x2plus.pth";
        upscaleModelScale = 2;
        finalScale = 1.5;
        sampler = [
          721897303308196
          "increment"
          15
          5
          "dpmpp_sde"
          "karras"
          0.3
        ];
      };
    }}

    cp ${license} "$out/LICENSE"
  ''
