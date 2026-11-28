{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkDefault;

  cfg = config.khanelinix.programs.graphical.wms.niri;
  stylixColors = config.lib.stylix.colors.withHashtag or null;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.niri.settings = {
      input = {
        keyboard = {
          xkb.layout = "us";
          repeat-delay = 600;
          repeat-rate = 25;
        };

        touchpad = {
          tap = { };
          dwt = { };
          natural-scroll = { };
          click-method = "clickfinger";
          accel-profile = "adaptive";
        };

        mouse.accel-profile = "flat";
      };

      layout = {
        gaps = mkDefault 16;
        center-focused-column = "on-overflow";

        focus-ring = {
          width = mkDefault 4;
          active-color = mkDefault "#81A1C1";
          inactive-color = mkDefault "#4C566A";
        };

        preset-column-widths._children = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
          { proportion = 1.0; }
        ];

        default-column-width.proportion = 0.5;
      }
      // lib.optionalAttrs ((config.stylix.enable or false) && stylixColors != null) {
        border = {
          width = mkDefault 4;
          active-color = mkDefault stylixColors.base0D;
          inactive-color = mkDefault stylixColors.base03;
        };
      };

      cursor = mkIf config.home.pointerCursor.enable {
        xcursor-theme = config.home.pointerCursor.name;
        xcursor-size = config.home.pointerCursor.size;
      };

      environment = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };

      prefer-no-csd = { };

      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      animations.workspace-switch.spring._props = {
        damping-ratio = 1.0;
        stiffness = 1000;
        epsilon = 0.0001;
      };
    };
  };
}
