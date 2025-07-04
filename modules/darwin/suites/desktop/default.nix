{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.desktop;
in
{
  options.${namespace}.suites.desktop = {
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
      # Broken nixpkgs
      # xquartz
    ];

    ${namespace}.desktop = {
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
        "ghostty"
        "gpg-suite"
        "hammerspoon"
        "launchcontrol"
        "sf-symbols"
        "xquartz"
      ];

      taps = [
        "beeftornado/rmtree"
        "felixkratz/homebrew-formulae"
      ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
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
