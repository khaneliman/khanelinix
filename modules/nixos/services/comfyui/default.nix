{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.services.comfyui;

  models = [
    {
      url = "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/7beb7b647f04469fbe64ba8adc2bb0d7e5e9f73f/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors";
      target = "text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors";
      hash = "sha256-y1Y22FKg6mqQdasb70lsDbeu8TwCNQVx44iuqVnFwLQ=";
    }
    {
      url = "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/7beb7b647f04469fbe64ba8adc2bb0d7e5e9f73f/split_files/vae/qwen_image_vae.safetensors";
      target = "vae/qwen_image_vae.safetensors";
      hash = "sha256-pwWA8CE+Z5Z+6clfBbtADo+wgwfgF6kkvzRBIj4CPR8=";
    }
    {
      url = "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/7beb7b647f04469fbe64ba8adc2bb0d7e5e9f73f/split_files/diffusion_models/qwen_image_2512_fp8_e4m3fn.safetensors";
      target = "diffusion_models/qwen_image_2512_fp8_e4m3fn.safetensors";
      hash = "sha256-XcgFVNXYM5AEai9KlOzgavt3AL97Cq+L3pdpeTh1h2s=";
    }
    {
      url = "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/984166f60a9b1fcede5e9b9287b7a7aebc050010/split_files/diffusion_models/qwen_image_edit_2511_int8_convrot.safetensors";
      target = "diffusion_models/qwen_image_edit_2511_int8_convrot.safetensors";
      hash = "sha256-EbWvWsYBgh1zkwyEhGyaFY5nF3NW2vknzhyNEPOWOCk=";
    }
    {
      url = "https://huggingface.co/lightx2v/Qwen-Image-2512-Lightning/resolve/c35c0e2ab8891698dace27aac7b64bc6c4f1a8ea/Qwen-Image-2512-Lightning-4steps-V1.0-bf16.safetensors";
      target = "loras/Qwen-Image-2512-Lightning-4steps-V1.0-bf16.safetensors";
      hash = "sha256-3g0jblTs8sQ7MkR9E0eMbq4NNhsf7UjGlnWwhPokDYc=";
    }
    {
      url = "https://huggingface.co/lightx2v/Qwen-Image-Edit-2511-Lightning/resolve/d74eba145674fd7e31b949324e148e21e7118abd/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors";
      target = "loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors";
      hash = "sha256-IiJujQXTVLs1ZifUKICfWv14GTmbB3I4orcKgog6kE8=";
    }
  ];

  # Realize models before activation. ComfyUI consumes the read-only store paths.
  modelRoot = pkgs.linkFarm "comfyui-models" (
    map (model: {
      name = model.target;
      path = pkgs.fetchurl {
        name = baseNameOf model.target;
        inherit (model) hash url;
        meta.license = lib.licenses.asl20;
      };
    }) models
  );

  extraModelPaths = (pkgs.formats.yaml { }).generate "comfyui-extra-model-paths.yaml" {
    khanelinix = {
      base_path = modelRoot;
      diffusion_models = "diffusion_models";
      loras = "loras";
      text_encoders = "text_encoders";
      vae = "vae";
    };
  };
in
{
  options.khanelinix.services.comfyui.enable = lib.mkEnableOption "local ComfyUI image generation";

  config = lib.mkIf cfg.enable {
    services.comfyui = {
      enable = true;
      extraArgs = [
        # ComfyUI 0.33.1 leaves its ROCm INT8 Triton backend opt-in.
        "--enable-triton-backend"
        "--extra-model-paths-config=${extraModelPaths}"
        # This GPU also drives two high-resolution displays. Preserve compositor headroom.
        "--reserve-vram=2"
      ];
    };
  };
}
