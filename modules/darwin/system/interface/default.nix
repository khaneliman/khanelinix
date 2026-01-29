{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.system.interface;
  hmCfg = config.home-manager.users.${config.khanelinix.user.name};
in
{
  options.khanelinix.system.interface = {
    enable = mkEnableOption "macOS interface";
  };

  config = mkIf cfg.enable {
    khanelinix.home.file = {
      "Pictures/screenshots/.keep".text = "";
    };

    system.defaults = {
      CustomSystemPreferences = {
        finder = {
          DisableAllAnimations = true;
          FXEnableExtensionChangeWarning = false;
          QuitMenuItem = true;
          ShowExternalHardDrivesOnDesktop = false;
          ShowHardDrivesOnDesktop = false;
          ShowMountedServersOnDesktop = false;
          ShowPathbar = true;
          ShowRemovableMediaOnDesktop = false;
          _FXSortFoldersFirst = true;
        };

        NSGlobalDomain = {
          AppleAccentColor = 1;
          AppleHighlightColor = "0.65098 0.85490 0.58431";
          AppleSpacesSwitchOnActivate = false;
          WebKitDeveloperExtras = true;
        };
      };

      CustomUserPreferences = {
        "com.apple.Terminal" = {
          # skhd requires Secure Keyboard Entry to be disabled.
          SecureKeyboardEntry = !hmCfg.services.skhd.enable;
        };
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          AutomaticDownload = 1;
          CriticalUpdateInstall = 1;
          ScheduleFrequency = 1;
        };
      };

      # dock settings
      dock = {
        # auto show and hide dock
        autohide = true;
        # remove delay for showing dock
        autohide-delay = 0.0;
        # how fast is the dock showing animation
        autohide-time-modifier = 1.0;
        mineffect = "scale";
        minimize-to-application = true;
        mouse-over-hilite-stack = true;
        mru-spaces = false;
        orientation = "bottom";
        show-process-indicators = true;
        show-recents = false;
        showhidden = false;
        static-only = false;
        tilesize = 50;

        # Hot corners
        # Possible values:
        #  0: no-op
        #  2: Mission Control
        #  3: Show application windows
        #  4: Desktop
        #  5: Start screen saver
        #  6: Disable screen saver
        #  7: Dashboard
        # 10: Put display to sleep
        # 11: Launchpad
        # 12: Notification Center
        # 13: Lock Screen
        # 14: Quick Notes
        wvous-tl-corner = 2;
        wvous-tr-corner = 12;
        wvous-bl-corner = 14;
        wvous-br-corner = 4;

        persistent-apps =
          let
            hmApps = "/Users/${config.khanelinix.user.name}/Applications/Home Manager Apps";
            hasPkg = p: builtins.any (x: (x.pname or x.name) == p) hmCfg.home.packages;

            systemApps = [
              "/System/Applications/System Settings.app"
              "/System/Applications/App Store.app"
            ];

            socialApps = lib.optionals config.khanelinix.suites.social.enable (
              lib.optional (hmCfg.khanelinix.programs.graphical.apps.caprine.enable or false
              ) "${hmApps}/Caprine.app"
              ++ lib.optional (hasPkg "element-desktop") "${hmApps}/Element.app"
              ++ lib.optional (hasPkg "teams-for-linux") { app = "${hmApps}/teams-for-linux.app"; }
              ++ lib.optional (hmCfg.khanelinix.programs.graphical.apps.vesktop.enable or false
              ) "${hmApps}/Vesktop.app"
              ++ lib.optional (hmCfg.programs.thunderbird.enable or false) {
                app = "${hmApps}/Thunderbird.app";
              }
            );

            communicationApps = [ "/System/Applications/Messages.app" ] ++ socialApps;

            browserApps =
              lib.optional (hmCfg.programs.firefox.enable or false) {
                app = "${hmCfg.programs.firefox.package}/Applications/Firefox${
                  lib.optionalString (
                    hmCfg.programs.firefox.package.pname == "firefox-devedition"
                  ) "Developer Edition"
                }.app";
              }
              ++ [ "/Applications/Safari.app" ];

            productivityApps =
              lib.optional (config.khanelinix.tools.homebrew.enable && config.khanelinix.suites.business.enable) {
                app = "/Applications/Fantastical.app";
              }
              ++ [
                "/System/Applications/Reminders.app"
                "/System/Applications/Notes.app"
              ];

            mediaApps = [
              "/System/Applications/Music.app"
            ]
            ++ lib.optional (config.khanelinix.tools.homebrew.enable && config.khanelinix.suites.video.enable) {
              app = "/Applications/Plex.app";
            };

            devApps = lib.optionals config.khanelinix.suites.development.enable (
              lib.optional (hmCfg.khanelinix.programs.graphical.editors.vscode.enable or false
              ) "${hmApps}/Visual Studio Code.app"
              ++ lib.optional (hasPkg "bruno") "${hmApps}/Bruno.app"
            );

            terminalApps = [ "${hmApps}/kitty.app" ];

            spacer = {
              spacer = {
                small = true;
              };
            };
          in
          systemApps
          ++ [ spacer ]
          ++ communicationApps
          ++ [ spacer ]
          ++ browserApps
          ++ productivityApps
          ++ [ spacer ]
          ++ mediaApps
          ++ [ spacer ]
          ++ devApps
          ++ lib.optional (devApps != [ ]) spacer
          ++ terminalApps;
      };

      # file viewer settings
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = true;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        # NOTE: Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
        FXPreferredViewStyle = "Nlsv";
        QuitMenuItem = true;
        ShowStatusBar = false;
        _FXShowPosixPathInTitle = true;
      };

      # login window settings
      loginwindow = {
        # disable guest account
        GuestEnabled = false;
        # show name instead of username
        SHOWFULLNAME = false;
      };

      menuExtraClock = {
        ShowAMPM = true;
        ShowDate = 1;
        ShowDayOfWeek = true;
        ShowSeconds = true;
      };

      NSGlobalDomain = {
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.sound.beep.volume" = 0.0;
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "Automatic";
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        _HIHideMenuBar = hmCfg.programs.sketchybar.enable;
      };

      screencapture = {
        disable-shadow = true;
        location = "/Users/${config.khanelinix.user.name}/Pictures/screenshots/";
        type = "png";
      };

      spaces.spans-displays = !config.services.yabai.enable;

      universalaccess = {
        reduceMotion = false;
      };
    };
  };
}
