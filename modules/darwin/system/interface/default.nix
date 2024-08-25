{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.system.interface;
in
{
  options.${namespace}.system.interface = {
    enable = mkEnableOption "macOS interface";
  };

  config = mkIf cfg.enable {
    system.defaults = {
      CustomSystemPreferences = {
        finder = {
          DisableAllAnimations = true;
          ShowExternalHardDrivesOnDesktop = false;
          ShowHardDrivesOnDesktop = false;
          ShowMountedServersOnDesktop = false;
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

      # login window settings
      loginwindow = {
        # disable guest account
        GuestEnabled = false;
        # show name instead of username
        SHOWFULLNAME = false;
      };

      # file viewer settings
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        # NOTE: Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
        FXPreferredViewStyle = "Nlsv";
        QuitMenuItem = true;
        ShowStatusBar = false;
        _FXShowPosixPathInTitle = true;
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

        # sudo su "$USER" -c "defaults write com.apple.dock persistent-apps -array 	\
        # '$launchpad' '$settings' '$appstore' '$small_blank' 																		\
        # '$messages' '$messenger' '$teams' '$discord' '$mail' '$small_blank' 										\
        # '$firefox' '$safari' '$fantastical' '$reminders' '$notes' '$small_blank' 								\
        # '$music' '$spotify' '$plex' '$small_blank' 																							\
        # '$code' '$github' '$gitkraken' '$small_blank' 													\
        # '$alacritty' '$kitty'"
        # Larger spacer
        # {tile-data={}; tile-type="spacer-tile";}
        # Small spacer
        # ''{tile-data={}; tile-type="small-spacer-tile";}''
        persistent-apps = [
          "/System/Applications/Launchpad.app"
          "/System/Applications/System Settings.app"
          "/System/Applications/App Store.app"
          # TODO: implement small_blank
          # Need to update upstream to accept something like this
          # ''{tile-data={}; tile-type="small-spacer-tile";}''
          "/System/Applications/Messages.app"
          "/Applications/Caprine.app"
          "/Applications/Element.app"
          "/Applications/Microsoft Teams (work or school).app"
          "/Applications/Discord.app"
          "/Applications/Thunderbird.app"
          # TODO: implement small_blank
          "/Applications/Firefox Developer Edition.app"
          "/Applications/Safari.app"
          "/Applications/Fantastical.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Notes.app"
          # TODO: implement small_blank
          "/System/Applications/Music.app"
          "/Applications/Spotify.app"
          "/Applications/Plex.app"
          # TODO: implement small_blank
          "/Applications/Visual Studio Code.app"
          "/Applications/Visual Studio (Preview).app"
          "/Applications/GitHub Desktop.app"
          "/Applications/GitKraken.app"
          # TODO: implement small_blank
          "${pkgs.wezterm}/Applications/WezTerm.app"
        ];
      };

      screencapture = {
        disable-shadow = true;
        location = "$HOME/Pictures/screenshots/";
        type = "png";
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
        NSAutomaticWindowAnimationsEnabled = false;
        _HIHideMenuBar = true;
      };
    };
  };
}
