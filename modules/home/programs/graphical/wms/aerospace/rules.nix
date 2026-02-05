{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.wms.aerospace;
  sketchybar = lib.getExe (config.programs.sketchybar.finalPackage or pkgs.sketchybar);
in
{
  config = lib.mkIf cfg.enable {
    programs.aerospace.settings = {
      # Window detection rules for workspace assignment
      on-window-detected =
        let
          mkWorkspaceRules =
            workspace: appIds:
            map (appId: {
              "if" = {
                app-id = appId;
              };
              run = "move-node-to-workspace ${workspace}";
            }) appIds;

          browserApps = [
            "org.mozilla.firefoxdeveloperedition"
            "org.mozilla.firefox"
            "com.google.Chrome"
            "com.apple.Safari"
          ];

          communicationApps = [
            "com.microsoft.teams2"
            "com.apple.mail"
            "com.apple.MobileSMS"
            "com.readdle.smartemail-Mac"
            "com.hnc.Discord"
            "org.mozilla.thunderbird"
            "org.mozilla.Thunderbird"
            "org.nixos.thunderbird"
            "com.facebook.archon.developerID"
            "com.facebook.messenger.desktop"
            "com.tinyspeck.slackmacgap"
            "ru.keepcoder.Telegram"
            "im.riot.app"
            "dev.vencord.Vesktop"
          ];

          developmentApps = [
            "io.qt.QtCreator"
            "com.microsoft.VSCode"
            "com.microsoft.visual-studio"
            "com.apple.dt.Xcode"
          ];

          gitApps = [
            "com.github.GitHubClient"
            "com.axosoft.gitkraken"
          ];

          productivityApps = [
            "com.apple.Notes"
            "com.apple.reminders"
            "com.apple.iCal"
            "com.flexibits.fantastical2.mac"
          ];

          mediaApps = [
            "com.apple.Music"
            "tv.plex.desktop"
            "com.spotify.client"
            "org.videolan.vlc"
          ];

          vmApps = [
            "com.utmapp.UTM"
            "com.parallels.desktop.console"
          ];
        in
        lib.flatten [
          [
            {
              check-further-callbacks = true;
              run = "exec-and-forget ${sketchybar} --trigger aerospace_windows_change";
            }
            {
              "if" = {
                app-id = "com.apple.systempreferences";
              };
              run = "layout tiling";
            }
          ]
          # Browsers -> workspace 1 (main)
          (mkWorkspaceRules "1" browserApps)
          # Communication apps -> workspace 2 (comms)
          (mkWorkspaceRules "2" communicationApps)
          # Development tools -> workspace 3 (code)
          (mkWorkspaceRules "3" developmentApps)
          # Git tools -> workspace 4 (ref)
          (mkWorkspaceRules "4" gitApps)
          # Productivity apps -> workspace 5 (productivity)
          (mkWorkspaceRules "5" productivityApps)
          # Media apps -> workspace 6 (media)
          (mkWorkspaceRules "6" mediaApps)
          # VMs -> workspace 7 (vm)
          (mkWorkspaceRules "7" vmApps)
        ];

    };
  };
}
