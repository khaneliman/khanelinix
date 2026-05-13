{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        layer_rule =
          lib.concatMap
            (
              namespace:
              map (attrs: attrs // { match.namespace = namespace; }) [
                { blur = true; }
                { blur_popups = true; }
                { dim_around = true; }
              ]
            )
            [
              "anyrun"
              "sherlock"
              "walker"
              "vicinae"
            ];
      };
    };
  };
}
