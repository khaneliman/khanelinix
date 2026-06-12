{
  config,
  lib,
  options,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkAfter mkIf;
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.wms.niri;
  niriAvailable = options ? programs.niri;
  socialIncludes = suiteProfileIncludes config config.khanelinix.suites.social;
  businessIncludes = suiteProfileIncludes config config.khanelinix.suites.business;

  mkStartCommand =
    cmd:
    if (osConfig.programs.uwsm.enable or false) then
      "uwsm app -p TimeoutStopSec=15s -- ${cmd}"
    else
      cmd;
in
{
  config = mkIf cfg.enable (
    lib.optionalAttrs niriAvailable {
      programs.niri.settings.spawn-at-startup = mkAfter (
        lib.optionals config.programs.firefox.enable [
          { sh = mkStartCommand (lib.getExe config.programs.firefox.package); }
        ]
        ++ lib.optionals (osConfig.programs.steam.enable or false) [
          { sh = mkStartCommand "steam"; }
        ]
        ++ lib.optionals (config.khanelinix.suites.social.enable && socialIncludes "standard") [
          { sh = mkStartCommand "element-desktop"; }
        ]
        ++ lib.optionals (config.khanelinix.suites.business.enable && businessIncludes "standard") [
          { sh = mkStartCommand "teams-for-linux"; }
          { sh = mkStartCommand "thunderbird"; }
        ]
        ++ lib.optionals (osConfig.services.hardware.openrgb.enable or false) [
          { sh = mkStartCommand "openrgb -c blue"; }
        ]
        ++ lib.optionals (osConfig.programs._1password-gui.enable or false) [
          { sh = mkStartCommand "1password --silent"; }
        ]
        ++ lib.optionals (osConfig.networking.networkmanager.enable or false) [
          { sh = mkStartCommand "nm-applet"; }
        ]
        ++ [
          { sh = mkStartCommand "wayvnc $(tailscale ip --4)"; }
        ]
      );
    }
  );
}
