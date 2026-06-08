{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.voxtype;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
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

        package = lib.mkDefault pkgs.voxtype-vulkan;
        loadModels = lib.mkDefault [ config.services.voxtype.settings.whisper.model ];
        wayland.display = lib.mkDefault "wayland-1";
        settings = lib.mkMerge [
          {
            state_file = lib.mkDefault "auto";
            hotkey.enabled = lib.mkDefault false;
            whisper = {
              model = lib.mkDefault "base.en";
              language = lib.mkDefault "en";
            };
            output = {
              # Type via uinput (dotool) first. Citrix/RDP/VMs and games read
              # real evdev input and ignore the Wayland virtual-keyboard
              # protocol that wtype uses, so wtype output never reaches the
              # remote session. uinput presents a real kernel HID device.
              driver_order = lib.mkDefault [
                "dotool"
                "wtype"
                "ydotool"
                "clipboard"
              ];
              # uinput device needs to settle (and the target window to focus)
              # before keys land, or the first characters drop. Bump
              # type_delay_ms if Citrix still drops characters over the network.
              pre_type_delay_ms = lib.mkDefault 60;
            };
          }

          (lib.mkIf config.khanelinix.programs.graphical.wms.hyprland.enable {
            output = {
              pre_recording_command = lib.mkDefault "hyprctl dispatch 'hl.dsp.submap(\"voxtype_recording\")'";
              pre_output_command = lib.mkDefault "hyprctl dispatch 'hl.dsp.submap(\"voxtype_suppress\")'";
              post_output_command = lib.mkDefault "hyprctl dispatch 'hl.dsp.submap(\"reset\")'";
            };
          })

          (lib.mkIf
            (
              !config.khanelinix.programs.graphical.wms.hyprland.enable
              && config.khanelinix.programs.graphical.wms.sway.enable
            )
            {
              output = {
                pre_recording_command = lib.mkDefault "swaymsg mode voxtype_recording";
                pre_output_command = lib.mkDefault "swaymsg mode voxtype_suppress";
                post_output_command = lib.mkDefault "swaymsg mode default";
              };
            }
          )
        ];
      };
    })
  ];
}
