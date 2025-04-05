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
          "idleinhibit focus, class:^(steam_app).*"
          "idleinhibit focus, class:^(gamescope).*"
          "idleinhibit focus, class:.*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"
          "idleinhibit fullscreen, class:^(firefox)$"
          "idleinhibit fullscreen, title:.*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"
          "idleinhibit fullscreen, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
          "idleinhibit focus, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
          "idleinhibit focus, class:^(mpv|.+exe)$"
        ];
      };
    };
  };
}
