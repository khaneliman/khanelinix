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
  voxtypePackage = pkgs.voxtype-onnx.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./streaming-session-hooks.patch ];
  });
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

        package = voxtypePackage;
        loadModels = [ config.services.voxtype.settings.parakeet.model ];
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
              model = "parakeet-unified-en-0.6b";
              streaming = true;
              streaming_chunk_secs = 0.32;
              streaming_left_context_secs = 5.6;
              streaming_right_context_secs = 0.32;
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
