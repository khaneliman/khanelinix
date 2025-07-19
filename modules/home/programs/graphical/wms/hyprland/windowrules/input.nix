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
          # Require input
          "bordercolor rgba(ed8796FF), class:org.kde.polkit-kde-authentication-agent-1"
          "dimaround, class:org.kde.polkit-kde-authentication-agent-1"
          "stayfocused, class:org.kde.polkit-kde-authentication-agent-1"
          "stayfocused, class:Rofi"
          "nofocus, class:^(steam)$, title:^()$"
          "nofocus, class:^(xwaylandvideobridge)$"
          "stayfocused, class:it.mijorus.smile"
        ];
      };
    };
  };
}
