{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.wms.niri;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.niri.settings._children = [
      {
        window-rule = {
          geometry-corner-radius = 8.0;
          clip-to-geometry = true;
          draw-border-with-background = false;
        };
      }
      {
        window-rule._children = [
          { match._props.app-id = "^firefox$"; }
          { default-column-width.proportion = 0.75; }
        ];
      }
      {
        window-rule._children = [
          { match._props.app-id = "^pavucontrol$"; }
          { match._props.app-id = "^pwvucontrol$"; }
          { open-floating = true; }
        ];
      }
    ];
  };
}
