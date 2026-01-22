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
          #Browsers - Move all Firefox windows to workspace 2 by default
          "match:title .*(Firefox).*$, workspace 2"
          # Secondary Monitor Media
          # Exception rule to override the above rule - Media sites go to workspace 1
          "match:title .*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex).*(Firefox).*$, workspace 1" # TODO: Doesnt seem to work even though it says it matches

          "match:title ^(.*(hidden tabs - Workona)).*(Firefox).*$, workspace special:inactive" # TODO: Doesnt seem to work even though it says it matches
          # Code
          "match:class ^(Code)$, workspace 3"
          "match:class ^(neovide)$, workspace 3"
          "match:class ^(GitHub Desktop)$, workspace 3"
          "match:class ^(GitKraken)$, workspace 3"
          "match:class ^(robloxstudiobeta.exe)$, workspace 3"
          # Gaming
          "match:class ^(Steam|steam)$, workspace 4 silent"
          "match:class ^(Steam|steam)$, match:title ^(Steam|steam)$, workspace 4 silent"
          "match:class ^(steamwebhelper)$, workspace 4 silent"
          "match:class ^(steam)$, no_initial_focus on"
          "match:class ^(steam)$, focus_on_activate off"
          "match:class ^(gamescope|steam_app).*, workspace 4 silent"
          "match:class ^(heroic)$, workspace 4"
          "match:class ^(lutris)$, workspace 4"
          "match:class ^(steam_app).*, workspace 4"
          "match:class ^(org.vinegarhq.Sober)$, workspace 4"
          "match:class .*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*, workspace 4"
          "match:title .*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*, workspace 4"
          # Messaging
          "match:class ^(Slack)$, workspace 5 silent"
          "match:class ^(Caprine)$, workspace 5 silent"
          "match:class ^(org.telegram.desktop)$, workspace 5 silent"
          "match:class ^(discord)$, workspace 5 silent"
          "match:class ^(vesktop)$, workspace 5 silent"
          "match:class ^(zoom)$, workspace 5 silent"
          "match:class ^(Element)$, workspace 5 silent"
          "match:class ^(teams-for-linux)$, workspace 5 silent"
          # Mail
          "match:class ^(thunderbird)$, workspace 6 silent"
          "match:class ^(Mailspring)$, workspace 6 silent"
          # Media
          "match:class ^(mpv|vlc|mpdevil)$, workspace 7"
          "match:class ^(Spotify)$, workspace 7 silent"
          "match:title ^(Spotify)$, workspace 7 silent"
          "match:title ^(Spotify Free)$, workspace 7 silent"
          "match:class ^(elisa)$, workspace 7 silent"
          #Remote
          "match:class ^(virt-manager|qemu)$, workspace 8 silent"
          "match:class ^(gnome-connections)$, workspace 8 silent"
          "match:class ^(looking-glass-client)$, workspace 8"
          # Citrix
          "match:class ^(selfservice)$, workspace 8"
          "match:class ^(Wfica)$, workspace 8"
          "match:class ^(Icasessionmgr)$, workspace 8 silent"
        ];
      };
    };
  };
}
