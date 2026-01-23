{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.wms.niri;
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.window-rules = [
      {
        geometry-corner-radius = {
          top-left = 8.0;
          top-right = 8.0;
          bottom-left = 8.0;
          bottom-right = 8.0;
        };
        clip-to-geometry = true;
        draw-border-with-background = false;
      }
      {
        matches = [
          { app-id = "^firefox$"; }
        ];
        default-column-width = {
          proportion = 0.75;
        };
      }
      {
        matches = [
          { app-id = "^pavucontrol$"; }
        ];
        open-floating = true;
      }
    ];
  };
}
