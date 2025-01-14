{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
    enable = mkBoolOpt false "Whether or not to enable common desktop configuration.";
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
      # Broken nixpkgs
      # xquartz
    ];

    khanelinix.desktop = {
      addons = {
        skhd = mkDefault enabled;
        jankyborders = mkDefault enabled;
      };

      bars = {
        sketchybar = mkDefault enabled;
      };

      wms = {
        yabai = mkDefault enabled;
      };
    };

    homebrew = {
      brews = [
        "ical-buddy"
      ];

      casks = [
        "bitwarden"
        "firefox@developer-edition"
        "gpg-suite"
        "hammerspoon"
        "launchcontrol"
        "sf-symbols"
        "xquartz"
      ];

      taps = [
        "beeftornado/rmtree"
        "felixkratz/homebrew-formulae"
        "khanhas/tap"
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
