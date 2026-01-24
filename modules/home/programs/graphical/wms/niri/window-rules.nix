{
  config,
  lib,
  options,
  ...
}:
let
  inherit (lib) mkIf optionalAttrs;

  cfg = config.khanelinix.programs.graphical.wms.niri;
  niriAvailable = options ? programs.niri;
in
{
  config = mkIf cfg.enable (
    optionalAttrs niriAvailable {
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
    }
  );
}
