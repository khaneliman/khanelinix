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
          "fullscreen, class:^(steam_app).*, title:^(MTGA)$"
          "fullscreenstate 2 2, class:^(steam_app).*, title:^(MTGA)$"
        ];
      };
    };
  };
}
