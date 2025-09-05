{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.programs.graphical.wms.sway;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        startup =
          let
            # Helper function to conditionally prefix with uwsm
            mkStartCommand =
              cmd: if (osConfig.programs.uwsm.enable or false) then "uwsm app -- ${cmd}" else cmd;
          in
          (
            lib.optionals config.programs.firefox.enable [
              { command = mkStartCommand (getExe config.programs.firefox.package); }
            ]
            ++ lib.optionals config.programs.vesktop.enable [
              { command = mkStartCommand (getExe config.programs.vesktop.package); }
            ]
            ++ lib.optionals (osConfig.programs.steam.enable or false) [
              { command = mkStartCommand "steam"; }
            ]
            ++ lib.optionals config.khanelinix.suites.social.enable [
              { command = mkStartCommand "element-desktop"; }
            ]
            ++ lib.optionals config.khanelinix.suites.business.enable [
              { command = mkStartCommand "teams-for-linux"; }
              { command = mkStartCommand "thunderbird"; }
            ]
            ++ lib.optionals (osConfig.services.hardware.openrgb.enable or false) [
              { command = mkStartCommand "openrgb -c blue"; }
            ]
            ++ lib.optionals (osConfig.programs._1password-gui.enable or false) [
              { command = mkStartCommand "1password --silent"; }
            ]
            ++ lib.optionals (osConfig.services.tailscale.enable or false) [
              { command = mkStartCommand "tailscale-systray"; }
            ]
            ++ lib.optionals (osConfig.networking.networkmanager.enable or false) [
              { command = mkStartCommand "nm-applet"; }
            ]
          )
          ++ [
            { command = "wl-clip-persist --clipboard both"; }
            { command = "$(wayvnc $(tailscale ip --4))"; }
            { command = "notify-send --icon ~/.face -u normal \"Hello $(whoami)\""; }
          ];
      };
    };
  };
}
