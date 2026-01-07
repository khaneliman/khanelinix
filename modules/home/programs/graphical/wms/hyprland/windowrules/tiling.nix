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
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        windowrule = [
          # Fix apps not tiling
          "match:class ^(Spotify)$, tile on"
          "match:class ^(Spotify Free)$, tile on"
          "match:class ^(steam_app).*, match:title ^(Battle.net)$, tile on"
        ];
      };
    };
  };
}
