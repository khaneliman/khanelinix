{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.wms.sway;
  socialIncludes = suiteProfileIncludes config config.khanelinix.suites.social;
  businessIncludes = suiteProfileIncludes config config.khanelinix.suites.business;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        startup =
          let
            # Helper function to conditionally prefix with uwsm
            # Usage: mkStartCommand "command" or mkStartCommand { slice = "b"; } "command"
            mkStartCommand =
              let
                # Two-argument version: mkStartCommand { slice = "b"; } "command"
                withArgs =
                  args: cmd:
                  let
                    slice = args.slice or null;
                    timeoutStopSec =
                      args.timeoutStopSec or {
                        a = "15s";
                        b = "10s";
                        s = "30s";
                      }
                      .${if slice == null then "a" else slice} or "15s";
                  in
                  if (osConfig.programs.uwsm.enable or false) then
                    "uwsm app ${
                      lib.optionalString (slice != null) "-s ${slice} "
                    }-p TimeoutStopSec=${timeoutStopSec} -- ${cmd}"
                  else
                    cmd;

                # Single-argument version: mkStartCommand "command"
                withoutArgs =
                  cmd:
                  if (osConfig.programs.uwsm.enable or false) then
                    "uwsm app -p TimeoutStopSec=15s -- ${cmd}"
                  else
                    cmd;
              in
              args: if lib.isString args then withoutArgs args else withArgs args;
          in
          (
            lib.optionals (osConfig.programs.uwsm.enable or false) [ { command = "uwsm finalize"; } ]
            ++
              # Regular applications (app-graphical.slice) - actively used, interactive
              lib.optionals config.programs.firefox.enable [
                { command = mkStartCommand (getExe config.programs.firefox.package); }
              ]
            # Background applications (background-graphical.slice) - communication clients, often idle
            ++ lib.optionals config.programs.vesktop.enable [
              { command = mkStartCommand { slice = "b"; } (getExe config.programs.vesktop.package); }
            ]
            ++ lib.optionals (osConfig.programs.steam.enable or false) [
              { command = mkStartCommand { slice = "b"; } "steam"; }
            ]
            ++ lib.optionals (config.khanelinix.suites.social.enable && socialIncludes "standard") [
              { command = mkStartCommand { slice = "b"; } "element-desktop"; }
            ]
            ++ lib.optionals (config.khanelinix.suites.business.enable && businessIncludes "standard") [
              { command = mkStartCommand { slice = "b"; } "teams-for-linux"; }
              { command = mkStartCommand { slice = "b"; } "thunderbird"; }
            ]
            # System services and utilities (background-graphical.slice)
            ++ lib.optionals (osConfig.services.hardware.openrgb.enable or false) [
              { command = mkStartCommand { slice = "b"; } "openrgb -c blue"; }
            ]
            ++ lib.optionals (osConfig.programs._1password-gui.enable or false) [
              { command = mkStartCommand { slice = "b"; } "1password --silent"; }
            ]
            ++ lib.optionals (osConfig.networking.networkmanager.enable or false) [
              { command = mkStartCommand { slice = "b"; } "nm-applet"; }
            ]
          )
          ++ [
            { command = mkStartCommand { slice = "b"; } "$(wayvnc $(tailscale ip --4))"; }
            { command = "notify-send --icon ${config.home.homeDirectory}/.face -u normal \"Hello $(whoami)\""; }
          ];
      };
    };
  };
}
