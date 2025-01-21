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
  imports = [
    ./windowrules/floating.nix
    ./windowrules/workspace.nix
  ];

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        windowrulev2 = [
          # fix xwayland apps
          "rounding 0, xwayland:1, floating:1"
          "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
          "size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$"

          ##
          # ░█▀█░█▀█░█▀█░█▀▀░▀█▀░▀█▀░█░█
          # ░█░█░█▀▀░█▀█░█░░░░█░░░█░░░█░
          # ░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░▀░░░▀░
          ##
          "opaque, class:^(virt-manager)$,title:.*(on QEMU).*"
          "opaque, class:^(looking-glass-client)$"
          "opaque, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
          "dimaround, class:^(gcr-prompter)$"

          # Require input
          "bordercolor rgba(ed8796FF), class:org.kde.polkit-kde-authentication-agent-1"
          "dimaround, class:org.kde.polkit-kde-authentication-agent-1"
          "stayfocused, class:org.kde.polkit-kde-authentication-agent-1"
          "stayfocused, class:Rofi"
          "nofocus, class:^(steam)$, title:^()$"
          "nofocus, class:^(xwaylandvideobridge)$"
          "stayfocused, class:it.mijorus.smile"

          ##
          # ░▀█▀░█▀▄░█░░░█▀▀░▀█▀░█▀█░█░█░▀█▀░█▀▄░▀█▀░▀█▀
          # ░░█░░█░█░█░░░█▀▀░░█░░█░█░█▀█░░█░░█▀▄░░█░░░█░
          # ░▀▀▀░▀▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀░░▀▀▀░░▀░
          ##
          "idleinhibit focus, class:^(steam_app).*"
          "idleinhibit focus, class:^(gamescope).*"
          "idleinhibit focus, class:.*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"
          "idleinhibit fullscreen, title:.*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"
          "idleinhibit fullscreen, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
          "idleinhibit focus, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
          "idleinhibit focus, class:^(mpv|.+exe)$"

          ##
          # ░▀█▀░█▀▀░█▀█░█▀▄░▀█▀░█▀█░█▀▀
          # ░░█░░█▀▀░█▀█░█▀▄░░█░░█░█░█░█
          # ░░▀░░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀░▀▀▀
          ##
          "immediate, class:^(gamescope|steam_app).*"

          # xwaylandvideobridge
          "opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$"
          "noanim,class:^(xwaylandvideobridge)$"
          "noinitialfocus,class:^(xwaylandvideobridge)$"
          "maxsize 1 1,class:^(xwaylandvideobridge)$"
          "noblur,class:^(xwaylandvideobridge)$"
        ];
      };
    };
  };
}
