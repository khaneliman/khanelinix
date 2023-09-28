{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
    enable =
      mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fastfetch
    ];

    khanelinix.desktop.addons = {
      skhd = enabled;
      yabai = enabled;
      sketchybar = enabled;
    };

    homebrew = {
      brews = [
        "blueutil"
        "fisher"
        "ical-buddy"
        "ifstat"
        "switchaudio-osx"
      ];

      casks = [
        "alacritty"
        "alfred"
        "alt-tab"
        "appcleaner"
        "bartender"
        "bitwarden"
        "brightness"
        "firefox-developer-edition"
        "gpg-suite"
        "hammerspoon"
        "kitty"
        "launchcontrol"
        "lulu"
        "monitorcontrol"
        "raycast"
        "sf-symbols"
        "stats"
        "xquartz"
      ];

      taps = [
        "beeftornado/rmtree"
        "bramstein/webfonttools"
        "felixkratz/formulae"
        "khanhas/tap"
        "romkatv/powerlevel10k"
        "shaunsingh/sfmono-nerd-font-ligaturized"
        "teamookla/speedtest"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "AdGuard for Safari" = 1440147259;
        "AmorphousMemoryMark" = 1495719766;
        "Amphetamine" = 937984704;
        "AutoMounter" = 1160435653;
        "Cascadea" = 1432182561;
        "Dark Reader for Safari" = 1438243180;
        "Disk Speed Test" = 425264550;
        "Malwarebytes Browser Guard" = 1577761052;
        "Microsoft Remote Desktop" = 1295203466;
        "PopClip" = 445189367;
        "TestFlight" = 899247664;
        "WiFi Explorer" = 494803304;
      };
    };
  };
}
