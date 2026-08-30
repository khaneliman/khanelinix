{ lib, pkgs }:
# This host's curated Qwen image, Qwen edit, MiniMax H3, and Wan video weights.
let
  # nixpkgs has no OpenRAIL license attribute. Use restrictions make the
  # license non-free, but it still allows redistribution.
  openRailM = {
    fullName = "CreativeML Open RAIL-M License";
    url = "https://huggingface.co/spaces/CompVis/stable-diffusion-license";
    free = false;
    redistributable = true;
  };

  openRailPlusPlusM = {
    fullName = "CreativeML Open RAIL++-M License";
    url = "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md";
    free = false;
    redistributable = true;
  };

  minimaxH3Community = {
    fullName = "MiniMax H3 Community License Agreement";
    url = "https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/LICENSE";
    free = false;
    # Distribution is allowed only outside the license's excluded territories.
    redistributable = false;
  };

  wan21Vae = {
    url = "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/617a7633e636506f850e043bc4605f290a466a8e/split_files/vae/wan_2.1_vae.safetensors";
    hash = "sha256-L8OdMTWaSwpk9Vh22P9/qNeAlWriyxNGOwIj4VFIl2s=";
  };

  clipSegBaseUrl = "https://huggingface.co/mcmonkey/clipseg-rd64-refined-fp16/resolve/5de7a14cdcc31b84fa9ebea216e54fa880322812";
in
lib.mapAttrs
  (
    target: source:
    pkgs.fetchurl (
      lib.recursiveUpdate {
        name = baseNameOf target;
        meta.license = lib.licenses.asl20;
      } source
    )
  )
  {
    # SwarmClipSeg otherwise downloads these files into mutable ComfyUI state
    # during the first automatic segment refinement.
    "clipseg/clipseg-rd64-refined-fp16-safetensors/config.json" = {
      url = "${clipSegBaseUrl}/config.json";
      hash = "sha256-wCM3WWbTGzsTknZPe9kd9HCYzhn2LxGwJj2O7c9wi80=";
    };

    "clipseg/clipseg-rd64-refined-fp16-safetensors/merges.txt" = {
      url = "${clipSegBaseUrl}/merges.txt";
      hash = "sha256-n9aR98gDkhDg/O0VhlRmxlgg0JtjmIsBdL/iXeKZBRo=";
    };

    "clipseg/clipseg-rd64-refined-fp16-safetensors/model.safetensors" = {
      url = "${clipSegBaseUrl}/model.safetensors";
      hash = "sha256-O/zXsFtSb4Sc8YwxAv7ULEjvOWN3uOEbd3ppECnKEpU=";
    };

    "clipseg/clipseg-rd64-refined-fp16-safetensors/preprocessor_config.json" = {
      url = "${clipSegBaseUrl}/preprocessor_config.json";
      hash = "sha256-T7CevP12USBcqCmbmTwwCI5VNe81CnLUbFxFgO6sBEA=";
    };

    "clipseg/clipseg-rd64-refined-fp16-safetensors/special_tokens_map.json" = {
      url = "${clipSegBaseUrl}/special_tokens_map.json";
      hash = "sha256-xIZKk3aoQBkYQlvtcfwU/A6B+bWexFwc+WzMst9Qjqw=";
    };

    "clipseg/clipseg-rd64-refined-fp16-safetensors/tokenizer_config.json" = {
      url = "${clipSegBaseUrl}/tokenizer_config.json";
      hash = "sha256-THXVf9m9C+hHitLW+LnOvdSkUzjrEIVHMpwrYzNHbKY=";
    };

    "clipseg/clipseg-rd64-refined-fp16-safetensors/vocab.json" = {
      url = "${clipSegBaseUrl}/vocab.json";
      hash = "sha256-4Imtkro2g3oNMUM+VVyPRf5gGrXCIdT2B97TLZ96Q0k=";
    };

    "text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/7beb7b647f04469fbe64ba8adc2bb0d7e5e9f73f/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors";
      hash = "sha256-y1Y22FKg6mqQdasb70lsDbeu8TwCNQVx44iuqVnFwLQ=";
    };

    "vae/qwen_image_vae.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/7beb7b647f04469fbe64ba8adc2bb0d7e5e9f73f/split_files/vae/qwen_image_vae.safetensors";
      hash = "sha256-pwWA8CE+Z5Z+6clfBbtADo+wgwfgF6kkvzRBIj4CPR8=";
    };

    # TODO(ComfyUI): Restore Qwen BF16 when model loading stays below
    # the desktop-safe memory boundary. It reached about 31.3 GiB RSS.
    "diffusion_models/Qwen-Image-2512-Q5_K_S-5.10bpw.gguf" = {
      url = "https://huggingface.co/byteshape/Qwen-Image-2512-GGUF/resolve/6329dd4a8e5bb973d6898f39b90c678b6782a018/Qwen-Image-2512-Q5_K_S-5.10bpw.gguf";
      hash = "sha256-cUpdCHryZV8wBdHjGFCU5ESLAAtZKpwzgytyOI4RwZ4=";
    };

    "diffusion_models/qwen_image_edit_2511_int8_convrot.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/984166f60a9b1fcede5e9b9287b7a7aebc050010/split_files/diffusion_models/qwen_image_edit_2511_int8_convrot.safetensors";
      hash = "sha256-EbWvWsYBgh1zkwyEhGyaFY5nF3NW2vknzhyNEPOWOCk=";
    };

    "loras/Qwen-Image-2512-Lightning-4steps-V1.0-bf16.safetensors" = {
      url = "https://huggingface.co/lightx2v/Qwen-Image-2512-Lightning/resolve/c35c0e2ab8891698dace27aac7b64bc6c4f1a8ea/Qwen-Image-2512-Lightning-4steps-V1.0-bf16.safetensors";
      hash = "sha256-3g0jblTs8sQ7MkR9E0eMbq4NNhsf7UjGlnWwhPokDYc=";
    };

    "loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors" = {
      url = "https://huggingface.co/lightx2v/Qwen-Image-Edit-2511-Lightning/resolve/d74eba145674fd7e31b949324e148e21e7118abd/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors";
      hash = "sha256-IiJujQXTVLs1ZifUKICfWv14GTmbB3I4orcKgog6kE8=";
    };

    "diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/4cc1d817b6184899b41293954329f576cb5ae86b/diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors";
      hash = "sha256-6IkgLEHa+2exDWe5fw2FQVCANqYJCvI0JaXCYV0DxHo=";
      meta.license = [ minimaxH3Community ];
    };

    "diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/4cc1d817b6184899b41293954329f576cb5ae86b/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors";
      hash = "sha256-klX1K2Z3hFrSOPIN+q+pRycFNpQSerfyVcBI8Pk2V3k=";
      meta.license = [ minimaxH3Community ];
    };

    "text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/4cc1d817b6184899b41293954329f576cb5ae86b/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors";
      hash = "sha256-NaiNUQRCMf4zIwHXpiqoHj8sumL+vrRG4sHj4O928sY=";
    };

    "vae/minimax_h3_video_vae_fp16.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/4cc1d817b6184899b41293954329f576cb5ae86b/vae/minimax_h3_video_vae_fp16.safetensors";
      hash = "sha256-fB8TFJLn7drKrJBpphuBvdOd5cyWVh5nfF6rHNzl5SI=";
      meta.license = [ minimaxH3Community ];
    };

    "vae/minimax_h3_audio_vae_fp32.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/4cc1d817b6184899b41293954329f576cb5ae86b/vae/minimax_h3_audio_vae_fp32.safetensors";
      hash = "sha256-jlBdld0VYdR6vUPUI4/UDZuxrp4UftCky6d412rk20g=";
      meta.license = [ minimaxH3Community ];
    };

    "loras/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/4cc1d817b6184899b41293954329f576cb5ae86b/loras/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors";
      hash = "sha256-Izms3xm/4SP0a5ceo102eoStuF3kNifh7Or6WlsrER4=";
    };

    "loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/4cc1d817b6184899b41293954329f576cb5ae86b/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors";
      hash = "sha256-W5q1reFdB3VnbQGpByaKaaFGjcYDOzsNPe1VAvPruEw=";
    };

    # TODO(ROCm): Replace this fallback with Wan 2.2 TI2V 5B after AMD
    # resolves its documented Radeon Linux color-corruption issue.
    # https://rocm.docs.amd.com/projects/radeon-ryzen/en/docs-7.2/docs/limitations/limitationsrad.html
    "diffusion_models/wan2.1_t2v_1.3B_fp16.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/617a7633e636506f850e043bc4605f290a466a8e/split_files/diffusion_models/wan2.1_t2v_1.3B_fp16.safetensors";
      hash = "sha256-vlMQJM2QGMtbSMQM+7amGRZFsceS64v0+MHG4Q+STcU=";
    };

    "text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" = {
      url = "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/617a7633e636506f850e043bc4605f290a466a8e/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors";
      hash = "sha256-wzVdMBkfHwZrJtk/ugF66YCdzmxifdpfambqplEgT2g=";
    };

    # SwarmUI hard-codes the Wan subdirectory, while existing ComfyUI
    # workflows use the flat name. Both entries resolve to one store path.
    "vae/Wan/wan_2.1_vae.safetensors" = wan21Vae;
    "vae/wan_2.1_vae.safetensors" = wan21Vae;

    # An SDXL checkpoint bundles UNet, CLIP, and VAE, so no separate
    # text encoder or VAE entry is needed. FP16 halves the download
    # and the VRAM footprint against FP32.
    #
    # The HuggingFace metadata tags this RAIL-M, but SDXL 1.0 base is
    # RAIL++-M and derivatives keep at least its use restrictions.
    "checkpoints/CyberRealisticXLPlay_V10.0_FP16.safetensors" = {
      url = "https://huggingface.co/cyberdelia/CyberRealisticXL/resolve/c04ae13b465d19763561a834d625a3d504a4f315/CyberRealisticXLPlay_V10.0_FP16.safetensors";
      hash = "sha256-/V6HC1u85L3etk9LuOScV/hKt5PAJipQPwEjvkNeZn0=";
      meta.license = openRailPlusPlusM;
    };

    # The checkpoint bakes in a merge-drifted SD 1.5 VAE, so it does
    # decode standalone. The author recommends sd-vae-ft-mse over it
    # to clear artifacts, which is why the workflow loads that VAE.
    "checkpoints/Realistic_Vision_V6.0_NV_B1_fp16.safetensors" = {
      url = "https://huggingface.co/SG161222/Realistic_Vision_V6.0_B1_noVAE/resolve/9a857a696b9aabbf509073e0aa55ec8200b6ef7d/Realistic_Vision_V6.0_NV_B1_fp16.safetensors";
      hash = "sha256-xIv9FZzXplB7EoaF6WPDmPpyOZzvr69gN4HfUM6DbMc=";
      meta.license = openRailM;
    };

    # The official Real-ESRGAN X2 general-image model keeps the
    # learned intermediate close to the requested final size. Its
    # repository publishes the release asset under BSD-3-Clause.
    "upscale_models/RealESRGAN_x2plus.pth" = {
      url = "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x2plus.pth";
      hash = "sha256-Sfr9Rfj9eqjTGrKiLRTZG1NsNElKXP4x612Jwvomars=";
      meta.license = lib.licenses.bsd3;
    };

    # Retain UltraSharp for existing user-authored workflows. The
    # curated presets avoid it because a 4x intermediate exhausted
    # display VRAM headroom on this dual-display GPU.
    "upscale_models/4x-UltraSharp.safetensors" = {
      url = "https://huggingface.co/Kim2091/UltraSharp/resolve/920fe218c211f831b43cb30327f203e2b59f5dab/4x-UltraSharp.safetensors";
      hash = "sha256-NqNAtVCbaZ0sBstEXdwdPTkZmsc02IntbXkV9g4FvLw=";
      meta.license = lib.licenses.cc-by-nc-sa-40;
    };

    "vae/vae-ft-mse-840000-ema-pruned.safetensors" = {
      url = "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/629b3ad3030ce36e15e70c5db7d91df0d60c627f/vae-ft-mse-840000-ema-pruned.safetensors";
      hash = "sha256-c15MOkR6MlV2DX+GhF8J+TeAm6pSnBc3DYPkw3WPPHU=";
      meta.license = lib.licenses.mit;
    };
  }
