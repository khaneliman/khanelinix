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
        # The per-window `immediate` hint only takes effect when tearing is
        # allowed globally.
        general.allow_tearing = true;

        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        window_rule = [
          {
            match.class = "^(gamescope|steam_app).*";
            immediate = true;
          }
        ];
      };
    };
  };
}
