{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.desktop;
in {
  options.khanelinix.suites.desktop = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;

      masApps = {
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
        "MediaInfo" = 510620098;
      };
    };

    khanelinix = {
    };
  };
}
