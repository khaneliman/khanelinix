{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkAfter mkIf;

  cfg = config.khanelinix.programs.graphical.wms.niri;

  mkWorkspaceRule = workspace: match: {
    matches = [ match ];
    open-on-workspace = workspace;
  };
in
{
  config = mkIf cfg.enable {
    programs.niri.settings.window-rules = mkAfter [
      (mkWorkspaceRule "2" { app-id = "^(firefox|org.mozilla.firefox)$"; })
      (mkWorkspaceRule "1" {
        title = ".*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex).*(Firefox).*";
      })

      (mkWorkspaceRule "3" { app-id = "^(code|Code)$"; })
      (mkWorkspaceRule "3" { app-id = "^neovide$"; })
      (mkWorkspaceRule "3" { app-id = "^(github-desktop|GitHub Desktop)$"; })
      (mkWorkspaceRule "3" { app-id = "^gitkraken$"; })
      (mkWorkspaceRule "3" { app-id = "^robloxstudiobeta.exe$"; })

      (mkWorkspaceRule "4" { app-id = "^(steam|Steam)$"; })
      (mkWorkspaceRule "4" { app-id = "^steamwebhelper$"; })
      (mkWorkspaceRule "4" { app-id = "^(gamescope|steam_app).*$"; })
      (mkWorkspaceRule "4" { app-id = "^heroic$"; })
      (mkWorkspaceRule "4" { app-id = "^lutris$"; })
      (mkWorkspaceRule "4" { app-id = "^org.vinegarhq.Sober$"; })
      (mkWorkspaceRule "4" { app-id = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"; })
      (mkWorkspaceRule "4" { title = ".*(cemu|yuzu|Ryujinx|emulationstation|retroarch).*"; })

      (mkWorkspaceRule "5" { app-id = "^Slack$"; })
      (mkWorkspaceRule "5" { app-id = "^Caprine$"; })
      (mkWorkspaceRule "5" { app-id = "^org.telegram.desktop$"; })
      (mkWorkspaceRule "5" { app-id = "^(discord|vesktop)$"; })
      (mkWorkspaceRule "5" { app-id = "^zoom$"; })
      (mkWorkspaceRule "5" { app-id = "^Element$"; })
      (mkWorkspaceRule "5" { app-id = "^teams-for-linux$"; })

      (mkWorkspaceRule "6" { app-id = "^thunderbird$"; })
      (mkWorkspaceRule "6" { app-id = "^Mailspring$"; })

      (mkWorkspaceRule "7" { app-id = "^(mpv|vlc|mpdevil)$"; })
      (mkWorkspaceRule "7" { app-id = "^Spotify$"; })
      (mkWorkspaceRule "7" { title = "^(Spotify|Spotify Free)$"; })
      (mkWorkspaceRule "7" { app-id = "^elisa$"; })

      (mkWorkspaceRule "8" { app-id = "^(virt-manager|qemu)$"; })
      (mkWorkspaceRule "8" { app-id = "^gnome-connections$"; })
      (mkWorkspaceRule "8" { app-id = "^looking-glass-client$"; })
      (mkWorkspaceRule "8" { app-id = "^selfservice$"; })
      (mkWorkspaceRule "8" { app-id = "^Wfica$"; })
      (mkWorkspaceRule "8" { app-id = "^Icasessionmgr$"; })
    ];
  };
}
