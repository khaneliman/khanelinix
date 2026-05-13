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
          # Require input
          {
            match.class = "org.kde.polkit-kde-authentication-agent-1";
            border_color = "rgba(ed8796FF)";
          }
          {
            match.class = "org.kde.polkit-kde-authentication-agent-1";
            dim_around = true;
          }
          {
            match.class = "org.kde.polkit-kde-authentication-agent-1";
            stay_focused = true;
          }
          {
            match.class = "Rofi";
            stay_focused = true;
          }
          {
            match.class = "^(steam)$";
            match.title = "^()$";
            no_focus = true;
          }
          {
            match.class = "^(xwaylandvideobridge)$";
            no_focus = true;
          }
          {
            match.class = "it.mijorus.smile";
            stay_focused = true;
          }
        ];
      };
    };
  };
}
