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
        windowrulev2 = [
          # Fix apps not staying fullscreen
          "fullscreen, class:^(steam_app).*, title:^(MTGA)$"
          "fullscreenstate 2 2, class:^(steam_app).*, title:^(MTGA)$"
        ];
      };
    };
  };
}
