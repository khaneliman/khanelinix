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
        windowrulev2 = [
          # ░█░█░▀█▀░█▀█░█▀▄░█▀█░█░█░░░█▀▄░█░█░█░░░█▀▀░█▀▀
          # ░█▄█░░█░░█░█░█░█░█░█░█▄█░░░█▀▄░█░█░█░░░█▀▀░▀▀█
          # ░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀
          # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

          ##
          # ░█▀▀░█░░░█▀█░█▀█░▀█▀░▀█▀░█▀█░█▀▀
          # ░█▀▀░█░░░█░█░█▀█░░█░░░█░░█░█░█░█
          # ░▀░░░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀░▀░▀▀▀
          ##
          "float, class:Rofi"
          "float, class:viewnior"
          "float, class:feh"
          "float, class:wlogout"
          "float, class:file_progress"
          "float, class:confirm"
          "float, class:dialog"
          "float, class:download"
          "float, class:notification"
          "float, class:error"
          "float, class:splash"
          "float, class:confirmreset"
          "float, class:org.kde.polkit-kde-authentication-agent-1"
          "float, class:^(wdisplays)$"
          "size 1100 600, class:^(wdisplays)$"
          "float, class:^(blueman-manager)$"
          "float, class:^(nm-connection-editor)$"

          # floating terminal
          "float, title:^(floatterm)$"
          "size 1100 600, title:^(floatterm)$"
          "move center, title:^(floatterm)$"
          "animation slide, title:^(floatterm)$"

          # calendar reminders
          "float, class:^(thunderbird)$,title:.*(Reminders)$"
          "size 1100 600, class:^(thunderbird)$,title:.*(Reminders)$"
          "move 78% 6%, class:^(thunderbird)$,title:.*(Reminders)$"
          "pin, class:^(thunderbird)$,title:.*(Reminders)$"

          # thunar file operation progress
          "float, class:^(thunar)$,title:^(File Operation Progress)$"
          "size 800 600, class:^(thunar)$,title:^(File Operation Progress)$"
          "move 78% 6%, class:^(thunar)$,title:^(File Operation Progress)$"
          "pin, class:^(thunar)$,title:^(File Operation Progress)$"

          # Workspace 8 (VM) layout
          "size 1000 1330, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
          "float, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
          "move 80% 6%, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
          "float, class:^(looking-glass-client)$"
          "size 2360 1330, class:^(looking-glass-client)$"
          "move 25% 6%, class:^(looking-glass-client)$"
          "float,  class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"
          "size 2360 1330, class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"
          "move 25% 6%, class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"
          "float,  class:^(qemu)$"
          "size 2360 1330, class:^(qemu)$"
          "move 25% 6%, class:^(qemu)$"

          # make Firefox PiP window floating and sticky
          "float, title:^(Picture-in-Picture)$"
          "pin, title:^(Picture-in-Picture)$"

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

          ##
          # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀░░░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀
          # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀░░░█░░░█░█░█░█░█▀▀░░█░░█░█
          # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀
          ##

          # Secondary Monitor Media
          "workspace 1, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$" # TODO: Doesnt seem to work even though it says it matches
          #Browsers
          "workspace 2, title:^(?!.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
          "workspace special:inactive, title:^(.*(hidden tabs - Workona)).*(Firefox).*$" # TODO: Doesnt seem to work even though it says it matches
          # Code
          "workspace 3, class:^(Code)$"
          "workspace 3, class:^(neovide)$"
          "workspace 3, class:^(GitHub Desktop)$"
          "workspace 3, class:^(GitKraken)$"
          # Gaming
          "workspace 4 silent, class:^(Steam|steam)$"
          "workspace 4 silent, class:^(Steam|steam)., title:^(Steam|steam)$"
          "workspace 4 silent, class:^(gamescope|steam_app).*"
          "workspace 4, class:^(heroic)$"
          "workspace 4, class:^(lutris)$"
          "workspace 4, class:.*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"
          "workspace 4, title:.*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"
          # Messaging
          "workspace 5 silent, class:^(Slack)$"
          "workspace 5 silent, class:^(Caprine)$"
          "workspace 5 silent, class:^(org.telegram.desktop)$"
          "workspace 5 silent, class:^(discord)$"
          "workspace 5 silent, class:^(zoom)$"
          "workspace 5 silent, class:^(Element)$"
          "workspace 5 silent, class:^(teams-for-linux)$"
          # Mail
          "workspace 6 silent, class:^(thunderbird)$"
          "workspace 6 silent, class:^(Mailspring)$"
          # Media
          "workspace 7, class:^(mpv|vlc|mpdevil)$"
          "workspace 7 silent, class:^(Spotify)$"
          "workspace 7 silent, title:^(Spotify)$"
          "workspace 7 silent, title:^(Spotify Free)$"
          "tile, class:^(Spotify)$"
          "tile, class:^(Spotify Free)$"
          "workspace 7 silent, class:^(elisa)$"
          #Remote
          "workspace 8 silent, class:^(virt-manager|qemu)$"
          "workspace 8 silent, class:^(gnome-connections)$"
          "workspace 8, class:^(looking-glass-client)$"
        ];
      };
    };
  };
}
