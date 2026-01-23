{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkDefault;

  cfg = config.khanelinix.programs.graphical.wms.niri;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings = {
      input = {
        keyboard = {
          xkb.layout = "us";
          repeat-delay = 600;
          repeat-rate = 25;
        };

        touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
          click-method = "clickfinger";
          accel-profile = "adaptive";
        };

        mouse = {
          natural-scroll = false;
          accel-profile = "flat";
        };
      };

      layout = {
        gaps = mkDefault 16;
        center-focused-column = "on-overflow";

        focus-ring = {
          enable = true;
          width = mkDefault 4;
          active.color = mkDefault "#81A1C1";
          inactive.color = mkDefault "#4C566A";
        };

        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
          { proportion = 1.0; }
        ];

        default-column-width = {
          proportion = 0.5;
        };
      };

      cursor = {
        theme = config.khanelinix.theme.gtk.cursor.name;
        inherit (config.khanelinix.theme.gtk.cursor) size;
      };

      environment = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };

      prefer-no-csd = true;

      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      animations = {
        workspace-switch.kind.spring = {
          damping-ratio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
        horizontal-view-movement = { };
        window-open = { };
      };
    };
  };
}
