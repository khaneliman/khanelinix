{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        windowrule = [
          # Fix apps not tiling
          "tile, class:^(Spotify)$"
          "tile, class:^(Spotify Free)$"
          "tile, class:^(steam_app).*, title:^(Battle.net)$"
        ];
      };
    };
  };
}
