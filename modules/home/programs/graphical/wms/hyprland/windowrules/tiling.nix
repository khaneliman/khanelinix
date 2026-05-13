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
        window_rule = [
          # Fix apps not tiling
          {
            match.class = "^(Spotify|Spotify Free|Godot|org\\.godotengine\\.Godot)$";
            tile = true;
          }
          {
            match.class = "^(steam_app).*";
            match.title = "^(Battle.net)$";
            tile = true;
          }
        ];
      };
    };
  };
}
