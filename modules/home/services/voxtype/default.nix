{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  cfg = config.khanelinix.services.voxtype;
  hyprlandPackage =
    if osConfig ? programs.hyprland.enable && osConfig.programs.hyprland.enable then
      osConfig.programs.hyprland.package
    else
      config.wayland.windowManager.hyprland.package;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  # Voxtype only registers the multilingual Nemotron export, which misheard
  # about twice as much technical vocabulary as this English-only one.
  nemotronModel = pkgs.linkFarm "nemotron-speech-streaming-en-0.6b-int8" (
    lib.mapAttrs
      (
        name: hash:
        pkgs.fetchurl {
          url = "https://huggingface.co/lokkju/nemotron-speech-streaming-en-0.6b-int8/resolve/95df6c82aa796a3fc793f87633dcdb017ac12c07/${name}";
          inherit hash;
        }
      )
      {
        "encoder.onnx" = "sha256-0kvkr/GN2dKqNDPLicWkV99QFav3ngamPd52sc1jhrs=";
        "decoder_joint.onnx" = "sha256-yG1SfkriclGnQWCerd1EKbpcMgUOL1Ms6hBS2eIfTwk=";
        "tokenizer.model" = "sha256-B9TlpjhApTqy1NEG0odHaBQ/s/vdR5OLORDS2gW/sKk=";
      }
  );
in
{
  options.khanelinix.services.voxtype = {
    enable = lib.mkEnableOption "Voxtype speech-to-text daemon";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "khanelinix.services.voxtype is only supported on Linux.";
        }
      ];
    })

    (lib.mkIf (cfg.enable && isLinux) {
      services.voxtype = {
        enable = true;

        package = pkgs.voxtype-onnx;
        environment = {
          DOTOOL_PIPE = "%t/voxtype-dotool-pipe";
          PATH = lib.makeBinPath (
            [
              pkgs.coreutils
              pkgs.dotool
              pkgs.runtimeShellPackage
              pkgs.which
              pkgs.wl-clipboard
              pkgs.wtype
            ]
            ++ lib.optional config.khanelinix.programs.graphical.wms.hyprland.enable hyprlandPackage
            ++ lib.optional (
              !config.khanelinix.programs.graphical.wms.hyprland.enable
              && config.khanelinix.programs.graphical.wms.sway.enable
            ) config.wayland.windowManager.sway.package
          );
        };
        wayland.display = "wayland-1";
        settings = lib.mkMerge [
          {
            state_file = "auto";
            engine = "parakeet";
            hotkey = {
              enabled = false;
              mode = "toggle";
            };
            audio.max_duration_secs = 300;
            parakeet = {
              # Cache-aware streaming encodes each 560 ms chunk once, instead
              # of re-encoding seconds of left context per chunk.
              model = "${nemotronModel}";
              # Store paths carry no name Voxtype can detect the type from.
              model_type = "nemotron";
              streaming = true;
            };
            whisper = {
              model = "base.en";
              language = "en";
            };
            output = {
              # Type via uinput (dotool) first. Citrix/RDP/VMs and games read
              # real evdev input and ignore the Wayland virtual-keyboard
              # protocol that wtype uses, so wtype output never reaches the
              # remote session. uinput presents a real kernel HID device.
              driver_order = [
                "dotool"
                "wtype"
                "ydotool"
                "clipboard"
              ];
              # uinput device needs to settle (and the target window to focus)
              # before keys land, or the first characters drop. Bump
              # type_delay_ms if Citrix still drops characters over the network.
              pre_type_delay_ms = 60;
            };
          }

          (lib.mkIf config.khanelinix.programs.graphical.wms.hyprland.enable {
            output = {
              pre_recording_command = "hyprctl --instance 0 dispatch 'hl.dsp.submap(\"voxtype_suppress\")'";
              post_output_command = "hyprctl --instance 0 dispatch 'hl.dsp.submap(\"reset\")'";
            };
          })

          (lib.mkIf
            (
              !config.khanelinix.programs.graphical.wms.hyprland.enable
              && config.khanelinix.programs.graphical.wms.sway.enable
            )
            {
              output = {
                pre_recording_command = "swaymsg mode voxtype_suppress";
                post_output_command = "swaymsg mode default";
              };
            }
          )
        ];
      };

      systemd.user.services = {
        dotoold = {
          Unit.Description = "dotool daemon for low-latency keyboard injection";
          Service = {
            ExecStart = lib.getExe' pkgs.dotool "dotoold";
            Environment = [
              "DOTOOL_PIPE=%t/voxtype-dotool-pipe"
              "PATH=${
                lib.makeBinPath [
                  pkgs.coreutils
                  pkgs.procps
                ]
              }"
            ];
            Restart = "on-failure";
            RestartSec = "5s";
          };
          Install.WantedBy = [ "default.target" ];
        };

        voxtype.Unit = {
          Wants = [ "dotoold.service" ];
          After = [ "dotoold.service" ];
        };
      };
    })
  ];
}
