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
          #Browsers - Move all Firefox windows to workspace 2 by default
          "workspace 2, title:.*(Firefox).*$"
          # Secondary Monitor Media
          # Exception rule to override the above rule - Media sites go to workspace 1
          "workspace 1, title:.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex).*(Firefox).*$" # TODO: Doesnt seem to work even though it says it matches

          "workspace special:inactive, title:^(.*(hidden tabs - Workona)).*(Firefox).*$" # TODO: Doesnt seem to work even though it says it matches
          # Code
          "workspace 3, class:^(Code)$"
          "workspace 3, class:^(neovide)$"
          "workspace 3, class:^(GitHub Desktop)$"
          "workspace 3, class:^(GitKraken)$"
          "workspace 3, class:^(robloxstudiobeta.exe)$"
          # Gaming
          "workspace 4 silent, class:^(Steam|steam)$"
          "workspace 4 silent, class:^(Steam|steam)., title:^(Steam|steam)$"
          "workspace 4 silent, class:^(gamescope|steam_app).*"
          "workspace 4, class:^(heroic)$"
          "workspace 4, class:^(lutris)$"
          "workspace 4, class:^(steam_app).*"
          "workspace 4, class:^(org.vinegarhq.Sober)$"
          "workspace 4, class:.*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"
          "workspace 4, title:.*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"
          # Messaging
          "workspace 5 silent, class:^(Slack)$"
          "workspace 5 silent, class:^(Caprine)$"
          "workspace 5 silent, class:^(org.telegram.desktop)$"
          "workspace 5 silent, class:^(discord)$"
          "workspace 5 silent, class:^(vesktop)$"
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
          "workspace 7 silent, class:^(elisa)$"
          #Remote
          "workspace 8 silent, class:^(virt-manager|qemu)$"
          "workspace 8 silent, class:^(gnome-connections)$"
          "workspace 8, class:^(looking-glass-client)$"
          # Citrix
          "workspace 8, class:^(selfservice)$"
          "workspace 8, class:^(Wfica)$"
          "workspace 8, class:^(Icasessionmgr)$"
        ];
      };
    };
  };
}
