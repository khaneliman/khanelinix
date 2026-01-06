{ config, lib, ... }:
let
  cfg = config.khanelinix.programs.graphical.wms.aerospace;
in
{
  config = lib.mkIf cfg.enable {
    programs.aerospace.settings = {
      # Window detection rules for workspace assignment
      on-window-detected = [
        # Browsers -> workspace 1 (main)
        {
          "if" = {
            app-id = "org.mozilla.firefoxdeveloperedition";
          };
          run = "move-node-to-workspace 1";
        }
        {
          "if" = {
            app-id = "org.mozilla.firefox";
          };
          run = "move-node-to-workspace 1";
        }
        {
          "if" = {
            app-id = "com.google.Chrome";
          };
          run = "move-node-to-workspace 1";
        }
        {
          "if" = {
            app-id = "com.apple.Safari";
          };
          run = "move-node-to-workspace 1";
        }
        # Communication apps -> workspace 2 (comms)
        {
          "if" = {
            app-id = "com.microsoft.teams2";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "com.apple.mail";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "com.apple.MobileSMS";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "com.readdle.smartemail-Mac";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "com.hnc.Discord";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "org.mozilla.thunderbird";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "com.facebook.archon.developerID";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "com.facebook.messenger.desktop";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "com.tinyspeck.slackmacgap";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "ru.keepcoder.Telegram";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "im.riot.app";
          };
          run = "move-node-to-workspace 2";
        }
        {
          "if" = {
            app-id = "dev.vencord.Vesktop";
          };
          run = "move-node-to-workspace 2";
        }
        # Development tools -> workspace 3 (code)
        {
          "if" = {
            app-id = "io.qt.QtCreator";
          };
          run = "move-node-to-workspace 3";
        }
        {
          "if" = {
            app-id = "com.microsoft.VSCode";
          };
          run = "move-node-to-workspace 3";
        }
        {
          "if" = {
            app-id = "com.microsoft.visual-studio";
          };
          run = "move-node-to-workspace 3";
        }
        {
          "if" = {
            app-id = "com.apple.dt.Xcode";
          };
          run = "move-node-to-workspace 3";
        }
        # Git tools -> workspace 4 (ref)
        {
          "if" = {
            app-id = "com.github.GitHubClient";
          };
          run = "move-node-to-workspace 4";
        }
        {
          "if" = {
            app-id = "com.axosoft.gitkraken";
          };
          run = "move-node-to-workspace 4";
        }
        # Productivity apps -> workspace 5 (productivity)
        {
          "if" = {
            app-id = "com.apple.Notes";
          };
          run = "move-node-to-workspace 5";
        }
        {
          "if" = {
            app-id = "com.apple.reminders";
          };
          run = "move-node-to-workspace 5";
        }
        {
          "if" = {
            app-id = "com.apple.iCal";
          };
          run = "move-node-to-workspace 5";
        }
        {
          "if" = {
            app-id = "com.flexibits.fantastical2.mac";
          };
          run = "move-node-to-workspace 5";
        }
        # Media apps -> workspace 6 (media)
        {
          "if" = {
            app-id = "com.apple.Music";
          };
          run = "move-node-to-workspace 6";
        }
        {
          "if" = {
            app-id = "tv.plex.desktop";
          };
          run = "move-node-to-workspace 6";
        }
        {
          "if" = {
            app-id = "com.spotify.client";
          };
          run = "move-node-to-workspace 6";
        }
        {
          "if" = {
            app-id = "org.videolan.vlc";
          };
          run = "move-node-to-workspace 6";
        }
        # VMs -> workspace 7 (vm)
        {
          "if" = {
            app-id = "com.utmapp.UTM";
          };
          run = "move-node-to-workspace 7";
        }
        {
          "if" = {
            app-id = "com.parallels.desktop.console";
          };
          run = "move-node-to-workspace 7";
        }
      ];
    };
  };
}
