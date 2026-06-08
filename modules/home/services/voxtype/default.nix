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

        package = pkgs.voxtype-vulkan;
        loadModels = [ config.services.voxtype.settings.whisper.model ];
        wayland.display = "wayland-1";
        settings = lib.mkMerge [
          {
            state_file = "auto";
            hotkey.enabled = false;
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
              pre_recording_command = "hyprctl dispatch 'hl.dsp.submap(\"voxtype_recording\")'";
              pre_output_command = "hyprctl dispatch 'hl.dsp.submap(\"voxtype_suppress\")'";
              post_output_command = "hyprctl dispatch 'hl.dsp.submap(\"reset\")'";
            };
          })

          (lib.mkIf
            (
              !config.khanelinix.programs.graphical.wms.hyprland.enable
              && config.khanelinix.programs.graphical.wms.sway.enable
            )
            {
              output = {
                pre_recording_command = "swaymsg mode voxtype_recording";
                pre_output_command = "swaymsg mode voxtype_suppress";
                post_output_command = "swaymsg mode default";
              };
            }
          )
        ];
      };
    })
  ];
}
