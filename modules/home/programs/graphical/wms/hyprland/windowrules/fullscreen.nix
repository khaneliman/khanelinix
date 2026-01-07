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
          # Fix apps not staying fullscreen
          "match:class ^(steam_app).*, match:title ^(MTGA)$, fullscreen on"
          "match:class ^(steam_app).*, match:title ^(MTGA)$, fullscreen_state 2 2"
        ];
      };
    };
  };
}
