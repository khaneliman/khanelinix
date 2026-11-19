{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.wms.sway;
  socialIncludes = suiteProfileIncludes config config.khanelinix.suites.social;
  businessIncludes = suiteProfileIncludes config config.khanelinix.suites.business;

  startWayvnc = pkgs.writeShellScript "sway-start-wayvnc" ''
    address=$(${getExe (osConfig.services.tailscale.package or pkgs.tailscale)} ip --4) || exit 1
    if [ -z "$address" ]; then
      exit 1
    fi
    exec ${getExe pkgs.wayvnc} "$address"
  '';
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        startup =
          let
            mkStartCommand = lib.khanelinix.uwsmApp osConfig;
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
          )
          ++ [
            { command = mkStartCommand { slice = "b"; } "${startWayvnc}"; }
            { command = "notify-send --icon ${config.home.homeDirectory}/.face -u normal \"Hello $(whoami)\""; }
          ];
      };
    };
  };
}
