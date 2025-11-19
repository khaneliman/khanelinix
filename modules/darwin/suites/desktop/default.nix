{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
    enable = lib.mkEnableOption "common desktop configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      alt-tab-macos
      appcleaner
      bartender
      blueutil
      monitorcontrol
      raycast
      switchaudio-osx
      stats
      # FIXME: broken nixpkgs
      # xquartz
    ];

    khanelinix = {
      desktop = {
        wms = {
          yabai = mkDefault enabled;
        };
      };

      # Enable log rotation for desktop services
      services = {
        jankyborders = mkDefault enabled;
        skhd = mkDefault enabled;
      };

      programs.graphical.bars.sketchybar = mkDefault enabled;
    };

    homebrew = {
      brews = [
        "ical-buddy"
      ];

      casks = [
        "bitwarden"
        "ghostty"
        "gpg-suite"
        "hammerspoon"
        "launchcontrol"
        "sf-symbols"
      ];

      taps = [
        "beeftornado/rmtree"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "AmorphousMemoryMark" = 1495719766;
        "Amphetamine" = 937984704;
        "AutoMounter" = 1160435653;
        "Dark Reader for Safari" = 1438243180;
        "Disk Speed Test" = 425264550;
        "Microsoft Remote Desktop" = 1295203466;
        "PopClip" = 445189367;
        "TestFlight" = 899247664;
        "WiFi Explorer" = 494803304;
      };
    };
  };
}
