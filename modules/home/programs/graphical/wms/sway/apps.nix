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
          lib.optionals config.programs.firefox.enable [
            { command = getExe config.programs.firefox.package; }
          ]
          ++ lib.optionals config.programs.vesktop.enable [
            { command = getExe config.programs.vesktop.package; }
          ]
          ++ lib.optionals (osConfig.programs.steam.enable or false) [
            { command = "steam"; }
          ]
          ++ lib.optionals config.khanelinix.suites.social.enable [
            { command = "element-desktop"; }
          ]
          ++ lib.optionals config.khanelinix.suites.business.enable [
            { command = "teams-for-linux"; }
            { command = "thunderbird"; }
          ]
          ++ lib.optionals (osConfig.services.hardware.openrgb.enable or false) [
            { command = "openrgb -c blue"; }
          ]
          ++ lib.optionals (osConfig.programs._1password-gui.enable or false) [
            { command = "1password --silent"; }
          ]
          ++ lib.optionals (osConfig.services.tailscale.enable or false) [
            { command = "tailscale-systray"; }
          ]
          ++ lib.optionals (osConfig.networking.networkmanager.enable or false) [
            { command = "nm-applet"; }
          ]
          ++ [
            # Always start these utilities
            { command = "wl-clip-persist --clipboard both"; }
            { command = "$(wayvnc $(tailscale ip --4))"; }
            { command = "notify-send --icon ~/.face -u normal \"Hello $(whoami)\""; }
          ];
      };
    };
  };
}
