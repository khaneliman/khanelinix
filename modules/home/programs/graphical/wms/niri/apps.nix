{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkAfter mkIf;
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.wms.niri;
  socialIncludes = suiteProfileIncludes config config.khanelinix.suites.social;
  businessIncludes = suiteProfileIncludes config config.khanelinix.suites.business;

  mkStartCommand = lib.khanelinix.uwsmApp osConfig;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.niri.settings._children = mkAfter (
      map (command: { spawn-sh-at-startup = command; }) (
        lib.optionals config.programs.firefox.enable [
          (mkStartCommand (lib.getExe config.programs.firefox.package))
        ]
        ++ lib.optionals (osConfig.programs.steam.enable or false) [
          (mkStartCommand "steam")
        ]
        ++ lib.optionals (config.khanelinix.suites.social.enable && socialIncludes "standard") [
          (mkStartCommand "element-desktop")
        ]
        ++ lib.optionals (config.khanelinix.suites.business.enable && businessIncludes "standard") [
          (mkStartCommand "teams-for-linux")
          (mkStartCommand "thunderbird")
        ]
        ++ lib.optionals (osConfig.services.hardware.openrgb.enable or false) [
          (mkStartCommand "openrgb -c blue")
        ]
        ++ lib.optionals (osConfig.programs._1password-gui.enable or false) [
          (mkStartCommand "1password --silent")
        ]
        ++ [
          (mkStartCommand "wayvnc $(tailscale ip --4)")
        ]
      )
    );
  };
}
