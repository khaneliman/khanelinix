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
          "match:class org.kde.polkit-kde-authentication-agent-1, border_color rgba(ed8796FF)"
          "match:class org.kde.polkit-kde-authentication-agent-1, dim_around on"
          "match:class org.kde.polkit-kde-authentication-agent-1, stay_focused on"
          "match:class Rofi, stay_focused on"
          "match:class ^(steam)$, match:title ^()$, no_focus on"
          "match:class ^(xwaylandvideobridge)$, no_focus on"
          "match:class it.mijorus.smile, stay_focused on"
        ];
      };
    };
  };
}
