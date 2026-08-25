{
  config,
  inputs,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) enabled;
  inherit (lib) mkForce mkMerge;
in
{
  imports = [
    ./disks.nix
    ./hardware.nix
    ./network.nix
    ./specializations.nix
  ];

  khanelinix = {
    packageProfile = "standard";

    nix = {
      enable = true;
      # useLix = true;
    };

    archetypes = {
      gaming = enabled;
      personal = enabled;
      workstation = enabled;
    };

    environments = {
      home-network = enabled;
    };

    hardware.keyboards.advantage360 = enabled;

    display-managers = {
      gdm.monitors = ./monitors.xml;
      regreet.hyprlandOutput = builtins.readFile ./hyprlandOutput;
    };

    programs.graphical = {
      addons = {
        gamemode.gpuDevice = 1; # AMD GPU is on card1

        noisetorch = {
          enable = false;
          threshold = 95;
          device = "alsa_input.usb-Blue_Microphones_Yeti_Stereo_Microphone_LT_191128065321F39907D0_111000-00.analog-stereo";
          deviceUnit = "sys-devices-pci0000:00-0000:00:01.2-0000:02:00.0-0000:03:08.0-0000:08:00.3-usb3-3\\x2d2-3\\x2d2.1-3\\x2d2.1.4-3\\x2d2.1.4.3-3\\x2d2.1.4.3:1.0-sound-card3-controlC3.device";
        };
      };

      wms = mkMerge [
        {
          hyprland = {
            enable = true;
            gamemode.vrr.enable = true; # Odyssey G9 (DP-1) supports VRR
          };
          niri = {
            enable = true;
            package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
          };
        }
        {
          sway.enable = true;
        }
      ];
    };

    services = {
      avahi = enabled;

      comfyui = {
        enable = true;

        # Weight curation is a host choice. This set supports the curated Qwen
        # image, Qwen edit, and Wan video workflows.
        models =
          lib.mapAttrs
            (
              target: source:
              pkgs.fetchurl (
                source
                // {
                  name = baseNameOf target;
                  meta.license = lib.licenses.asl20;
                }
              )
            )
            {
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

              "vae/wan_2.1_vae.safetensors" = {
                url = "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/617a7633e636506f850e043bc4605f290a466a8e/split_files/vae/wan_2.1_vae.safetensors";
                hash = "sha256-L8OdMTWaSwpk9Vh22P9/qNeAlWriyxNGOwIj4VFIl2s=";
              };
            };

        # This GPU also drives two high-resolution displays. Preserve compositor
        # headroom.
        reserveVramGb = 2;
      };

      geoclue = enabled;

      llm = {
        enable = true;

        colibri = {
          # qwen36 is one of the two engines the HIP tier reaches, so this host
          # exercises it.
          hipSupport = true;
        };

        llamaSwap = {
          enable = true;

          # ollama converts some models with its own architecture names, such as
          # gptoss and glm4moelite, which llama.cpp does not recognize. Only
          # tags whose architecture matches upstream belong here, and ollama
          # keeps serving the rest.
          models = {
            "qwen3-6-27b" = {
              tag = "qwen3.6:27b";
              contextSize = 32768;
            };

            "qwen3-coder-30b" = {
              tag = "qwen3-coder:30b";
              contextSize = 32768;
              # An editing session sends bursts, so a 300 second hold avoids
              # the 20 second reload of 18 GB between prompts. ollama holds 60
              # seconds instead, because its callers are one-shot.
              ttl = 300;
            };

            # 35B total with 3B active. The int4 container is 23 GB, which
            # exceeds this card, so colibri streams the experts instead.
            "qwen36-colibri" = {
              backend = "colibri";
              modelDir = "/var/lib/llm/colibri/qwen36";
              contextSize = 32768;
              ttl = 300;

              # The tier needs one cache slot per declared expert or it disables
              # itself. A 12 GB budget leaves the compositor room. A 16 GB budget
              # filled the card to 23.9 of 24.0 GiB and the compositor glitched.
              gpu = "0";
              vramBudgetGb = 12;
              cacheSlots = 256;
            };
          };
        };
      };
      power = enabled;
      printing = enabled;

      tailscale = {
        enable = true;
      };

      sunshine = {
        enable = true;
      };

      snapper = {
        enable = true;
        configs = {
          # Example
          # Don't really store anything worth keeping backups here for
          # Documents = {
          #   ALLOW_USERS = [ "khaneliman" ];
          #   SUBVOLUME = "/home/khaneliman/Documents";
          #   TIMELINE_CLEANUP = true;
          #   TIMELINE_CREATE = true;
          # };
        };
      };

      openssh = {
        enable = true;
      };

      samba = {
        enable = true;
        shares =
          let
            mkShare =
              {
                sharePath,
                comment,
                readOnly ? false,
                ownerOnly ? false,
              }:
              {
                browseable = true;
                inherit comment;
                path = sharePath;
                only-owner-editable = ownerOnly;
                public = true;
                read-only = readOnly;
              };
          in
          {
            public = mkShare {
              comment = "Home Public folder";
              sharePath = "${config.users.users.${config.khanelinix.user.name}.home}/Public/";
            };

            games = mkShare {
              comment = "Games folder";
              sharePath = "/mnt/games/";
              ownerOnly = true;
            };
          };
      };
    };

    security = {
      # doas = enabled;
      keyring = enabled;
      sudo-rs = enabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.getFile "secrets/khanelinix/default.yaml";
      };
    };

    suites.development = {
      enable = true;
      aiEnable = true;
      dockerEnable = true;
      sqlEnable = true;
    };

    system = {
      boot = {
        enable = true;
        loader = "limine";
        secureBoot = true;
        plymouth = true;
        silentBoot = true;
        limine.resolution = "3840x2160x32";
      };

      fonts = enabled;
      networking.enable = true;
      time = enabled;
    };

    theme = {
      # gtk = enabled;
      # qt = enabled;
      stylix = {
        enable = true;
        theme = "tokyo-night-dark";
      };
      tokyonight = enabled;
    };
  };

  sops.secrets."khanelinix_khaneliman_ssh_key" = {
    sopsFile = lib.getFile "secrets/khanelinix/khaneliman/default.yaml";
  };

  programs.hyprland.withUWSM = false;

  services = {
    displayManager.defaultSession = "hyprland";
    irqbalance.enable = mkForce false;
    sunshine = {
      settings = {
        sunshine_name = "khanelinix";
        capture = "kms";
        encoder = "vaapi";
        adapter_name = "/dev/dri/by-path/pci-0000:0c:00.0-render";
        output_name = 1;
        audio_sink = "alsa_output.pci-0000_0e_00.4.analog-stereo";
        hevc_mode = 3;
        av1_mode = 3;
        global_prep_cmd = builtins.toJSON [
          {
            do = ''if command -v swaymsg >/dev/null 2>&1; then swaymsg "output * dpms on"; fi; if command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch 'hl.dsp.dpms({ action = "on" })'; fi'';
            undo = ''if command -v swaymsg >/dev/null 2>&1; then swaymsg "output * dpms off"; fi; if command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'; fi'';
          }
        ];
      };
    };
  };

  # Keep EFI usage predictable when specialisations multiply boot artifacts.
  boot.loader.systemd-boot.configurationLimit = mkForce 10;

  # Dev workstation: include developer/library man pages (man 2/3, devman outputs).
  documentation.dev.enable = true;

  system.stateVersion = "26.05";
}
