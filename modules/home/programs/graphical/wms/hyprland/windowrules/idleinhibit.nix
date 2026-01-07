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
          "match:class ^(steam_app).*, idle_inhibit focus"
          "match:class ^(gamescope).*, idle_inhibit focus"
          "match:class .*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*, idle_inhibit focus"
          "match:class ^(firefox)$, idle_inhibit fullscreen"
          "match:title .*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*, idle_inhibit fullscreen"
          "match:title ^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$, idle_inhibit fullscreen"
          "match:title ^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$, idle_inhibit focus"
          "match:class ^(mpv|.+exe)$, idle_inhibit focus"
        ];
      };
    };
  };
}
