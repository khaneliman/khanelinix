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
          #Browsers - Move all Firefox windows to workspace 2 by default
          {
            match.title = ".*(Firefox).*$";
            workspace = "2";
          }
          # Secondary Monitor Media
          # Exception rule to override the above rule - Media sites go to workspace 1
          {
            match.title = ".*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex).*(Firefox).*$";
            workspace = "1";
          } # TODO: Doesnt seem to work even though it says it matches

          {
            match.title = "^(.*(hidden tabs - Workona)).*(Firefox).*$";
            workspace = "special:inactive";
          } # TODO: Doesnt seem to work even though it says it matches
          # Code
          {
            match.class = "^(Code|neovide|GitHub Desktop|GitKraken|robloxstudiobeta.exe)$";
            workspace = "3";
          }
          # Gaming
          {
            match.class = "^(Steam|steam|steamwebhelper)$";
            workspace = "4 silent";
          }
          {
            match.class = "^(Steam|steam)$";
            match.title = "^(Steam|steam)$";
            workspace = "4 silent";
          }
          {
            match.class = "^(steam)$";
            no_initial_focus = true;
          }
          {
            match.class = "^(steam)$";
            focus_on_activate = false;
          }
          {
            match.class = "^(gamescope|steam_app).*";
            workspace = "4 silent";
          }
          {
            match.class = "^(heroic|lutris|org.vinegarhq.Sober)$";
            workspace = "4";
          }
          {
            match.class = "^(steam_app).*";
            workspace = "4";
          }
          {
            match.class = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*";
            workspace = "4";
          }
          {
            match.title = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*";
            workspace = "4";
          }
          # Messaging
          {
            match.class = "^(Slack|Caprine|org.telegram.desktop|discord|vesktop|zoom|Element|teams-for-linux)$";
            workspace = "5 silent";
          }
          # Mail
          {
            match.class = "^(thunderbird|Mailspring)$";
            workspace = "6 silent";
          }
          # Media
          {
            match.class = "^(mpv|vlc|mpdevil)$";
            workspace = "7";
          }
          {
            match.class = "^(Spotify|elisa)$";
            workspace = "7 silent";
          }
          {
            match.title = "^(Spotify|Spotify Free)$";
            workspace = "7 silent";
          }
          #Remote
          {
            match.class = "^(virt-manager|qemu|gnome-connections)$";
            workspace = "8 silent";
          }
          {
            match.class = "^(looking-glass-client)$";
            workspace = "8";
          }
          # Citrix
          {
            match.class = "^(selfservice|Wfica)$";
            workspace = "8";
          }
          {
            match.class = "^(Icasessionmgr)$";
            workspace = "8 silent";
          }
        ];
      };
    };
  };
}
