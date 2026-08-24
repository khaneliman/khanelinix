{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.services.comfyui;

  localFirstSettings = (pkgs.formats.json { }).generate "comfyui-local-first-settings.json" {
    "Comfy.RightSidePanel.IsOpen" = false;
    "Comfy.Templates.SelectedRunsOn" = [ "ComfyUI" ];
    "Comfy.Workflow.AutoSave" = "off";
    "Comfy.Workflow.Persist" = true;
  };

  workflowPresets = pkgs.callPackage ./workflows.nix { };

  # Realize models before activation. ComfyUI consumes the read-only store paths.
  modelRoot = pkgs.linkFarm "comfyui-models" cfg.models;

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
  options.khanelinix.services.comfyui = {
    enable = lib.mkEnableOption "local ComfyUI image and video generation";

    models = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      example = lib.literalExpression ''
        {
          "diffusion_models/qwen_image_fp8_e4m3fn.safetensors" = pkgs.fetchurl {
            name = "qwen_image_fp8_e4m3fn.safetensors";
            url = "https://huggingface.co/...";
            hash = "sha256-...";
          };
        }
      '';
      description = ''
        Model weights that ComfyUI reads through its extra model paths.

        Each key is a path relative to the model root, such as
        "diffusion_models/qwen_image_fp8_e4m3fn.safetensors". Each value is the
        fetched store path for that file. Weight curation is a host decision, so
        an empty set omits the extra model paths file and its flag.
      '';
    };

    reserveVramGb = lib.mkOption {
      type = lib.types.nullOr lib.types.numbers.nonnegative;
      default = null;
      example = 2;
      description = ''
        Gigabytes of VRAM that ComfyUI leaves free for other GPU consumers.

        null omits --reserve-vram, which lets ComfyUI claim the whole card.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.comfyui = {
      enable = true;
      extraArgs = [
        # ComfyUI 0.33.1 leaves its ROCm INT8 Triton backend opt-in.
        "--enable-triton-backend"
        # Keep local installs free of paid API nodes and frontend network requests.
        "--disable-api-nodes"
      ]
      ++ lib.optional (cfg.models != { }) "--extra-model-paths-config=${extraModelPaths}"
      ++ lib.optional (cfg.reserveVramGb != null) "--reserve-vram=${toString cfg.reserveVramGb}";
    };

    systemd.services.comfyui.preStart = lib.mkAfter ''
      install -d -m 0755 \
        /var/lib/comfyui/user/default \
        /var/lib/comfyui/user/default/workflows/khanelinix

      ln -sfnT ${./local_first} /var/lib/comfyui/custom_nodes/khanelinix_local_first

      seedPreset() {
        source=$1
        destination=$2

        if [[ ! -e "$destination" ]]; then
          cp "$source" "$destination"
          chmod 0644 "$destination"
        fi
      }

      seedPreset \
        ${workflowPresets}/01-qwen-image-2512.json \
        /var/lib/comfyui/user/default/workflows/khanelinix/01-qwen-image-2512.json
      seedPreset \
        ${workflowPresets}/02-qwen-image-edit-2511.json \
        /var/lib/comfyui/user/default/workflows/khanelinix/02-qwen-image-edit-2511.json
      seedPreset \
        ${workflowPresets}/03-wan2.2-video.json \
        /var/lib/comfyui/user/default/workflows/khanelinix/03-wan2.2-video.json

      settingsFile=/var/lib/comfyui/user/default/comfy.settings.json
      settingsTmp="$settingsFile.tmp"

      if [[ -f "$settingsFile" ]]; then
        ${lib.getExe pkgs.jq} --slurp '.[0] * .[1]' \
          "$settingsFile" ${localFirstSettings} > "$settingsTmp"
      else
        cp ${localFirstSettings} "$settingsTmp"
      fi

      chmod 0644 "$settingsTmp"
      mv "$settingsTmp" "$settingsFile"
    '';
  };
}
