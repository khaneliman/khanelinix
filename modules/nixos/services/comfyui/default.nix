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

  comfyUiGguf = pkgs.fetchFromGitHub {
    owner = "city96";
    repo = "ComfyUI-GGUF";
    rev = "6ea2651e7df66d7585f6ffee804b20e92fb38b8a";
    hash = "sha256-/ZwecgxTTMo9J1whdEJci8lEkOy/yP+UmjbpOAA3BvU=";
  };

  comfyUiGgufPythonPath = pkgs.python3Packages.makePythonPath [
    pkgs.python3Packages.gguf
    pkgs.python3Packages.protobuf
    pkgs.python3Packages.sentencepiece
  ];

  comfyUiWithGguf = pkgs.symlinkJoin {
    name = "comfyui-with-gguf";
    paths = [ pkgs.comfyui ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta.mainProgram = "comfyui";
    postBuild = ''
      rm "$out/bin/comfyui"
      makeWrapper ${pkgs.comfyui.pythonEnv}/bin/python3 "$out/bin/comfyui" \
        --add-flags ${pkgs.comfyui}/share/comfyui/main.py \
        --prefix PYTHONPATH : ${comfyUiGgufPythonPath}
    '';
  };

  # Realize models before activation. ComfyUI consumes the read-only store paths.
  modelRoot = pkgs.linkFarm "comfyui-models" cfg.models;

  extraModelPaths = (pkgs.formats.yaml { }).generate "comfyui-extra-model-paths.yaml" {
    khanelinix = {
      base_path = modelRoot;
      diffusion_models = "diffusion_models";
      loras = "loras";
      text_encoders = "text_encoders";
      unet = "diffusion_models";
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
      package = comfyUiWithGguf;
      extraArgs = [
        # TODO(ROCm): Retest SDPA when gfx1100 Qwen output is fixed.
        # Tracking: https://github.com/Comfy-Org/ComfyUI/issues/14335
        # PyTorch SDPA corrupts Qwen output on gfx1100.
        "--use-split-cross-attention"
        # TODO(ROCm): Retest Triton when Wan output matches eager kernels on gfx1100.
        # Triton produced corrupt Wan output on gfx1100.
        "--disable-triton-backend"
        # Recompute nodes instead of retaining large image and video tensors.
        "--cache-none"
        # Keep local installs free of paid API nodes and frontend network requests.
        "--disable-api-nodes"
      ]
      ++ lib.optional (cfg.models != { }) "--extra-model-paths-config=${extraModelPaths}"
      ++ lib.optional (cfg.reserveVramGb != null) "--reserve-vram=${toString cfg.reserveVramGb}";
    };

    systemd = {
      services.comfyui.preStart = lib.mkAfter ''
        install -d -m 0755 \
          /var/lib/comfyui/user/default \
          /var/lib/comfyui/user/default/workflows/khanelinix

        ln -sfnT ${./local_first} /var/lib/comfyui/custom_nodes/khanelinix_local_first
        ln -sfnT ${comfyUiGguf} /var/lib/comfyui/custom_nodes/ComfyUI-GGUF

        presetDir=/var/lib/comfyui/user/default/workflows/khanelinix
        presetState=/var/lib/comfyui/khanelinix-presets
        backupDir=/var/lib/comfyui/user/default/workflow-backups/khanelinix

        install -d -m 0755 "$presetState"

        # Seeding tracks the hash of what it last wrote. An untouched preset is
        # refreshed in place, so a corrected workflow reaches the host without
        # renaming the file. An edited one is left alone, because the hash no
        # longer matches. Neither case needs a new filename per revision.
        seedPreset() {
          source=$1
          name=$2
          destination=$presetDir/$name
          marker=$presetState/$name.sha256

          if [[ -e "$destination" ]]; then
            current=$(sha256sum < "$destination" | cut -d ' ' -f 1)

            if [[ -e "$marker" ]]; then
              seeded=$(cat "$marker" 2>/dev/null || true)
            else
              # Adopt presets from before hash tracking only when they still
              # match the declarative source. A different file is a user edit.
              seeded=$(sha256sum < "$source" | cut -d ' ' -f 1)
            fi

            if [[ "$current" != "$seeded" ]]; then
              return
            fi
          fi

          cp "$source" "$destination"
          chmod 0644 "$destination"
          sha256sum < "$destination" | cut -d ' ' -f 1 > "$marker"
        }

        # Retiring a preset name runs once. Leaving it unconditional would move
        # the file again every activation, including one the user later saved
        # back under that name.
        archivePreset() {
          name=$1
          source=$presetDir/$name
          marker=$presetState/$name.retired

          if [[ -e "$marker" ]]; then
            return
          fi

          if [[ -e "$source" ]]; then
            timestamp=$(date -u +%Y%m%dT%H%M%SZ)

            install -d -m 0755 "$backupDir"
            mv "$source" "$backupDir/$name.$timestamp"
          fi

          rm -f "$presetState/$name.sha256"
          touch "$marker"
        }

        archivePreset 01-qwen-image-2512.json
        archivePreset 01-qwen-image-2512-scaled.json
        archivePreset 01-qwen-image-2512-bf16.json
        archivePreset 01-qwen-image-2512-gguf.json
        archivePreset 03-wan2.2-video.json
        archivePreset 03-wan2.2-image-to-video.json
        archivePreset 03-wan2.2-text-to-video.json
        archivePreset 03-wan2.1-text-to-video.json
        archivePreset 03-wan2.2-14b-text-to-video-q5.json
        archivePreset 03-wan2.2-5b-video.json

        seedPreset \
          ${workflowPresets}/01-qwen-image-2512.json \
          01-qwen-image-2512-q5.json
        seedPreset \
          ${workflowPresets}/02-qwen-image-edit-2511.json \
          02-qwen-image-edit-2511.json
        seedPreset \
          ${workflowPresets}/03-wan2.1-video.json \
          03-wan2.1-1.3b-video.json

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

      slices.system-comfyui = {
        description = "ComfyUI resource-control slice";
        sliceConfig = {
          ManagedOOMMemoryPressure = "kill";
          ManagedOOMMemoryPressureLimit = "40%";
          ManagedOOMMemoryPressureDurationSec = "10s";
        };
      };

      services.comfyui.serviceConfig = {
        CPUWeight = 20;
        IOWeight = 20;
        MemoryHigh = "24G";
        MemoryMax = "26G";
        MemorySwapMax = 0;
        Nice = 10;
        OOMPolicy = "stop";
        OOMScoreAdjust = 750;
        Slice = "system-comfyui.slice";
      };
    };
  };
}
