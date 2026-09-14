{
  config,
  lib,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;
  socialIncludes = suiteProfileIncludes config config.khanelinix.suites.social;
  businessIncludes = suiteProfileIncludes config config.khanelinix.suites.business;
in
{
  config = mkIf cfg.enable {
    # NOTE: xdgautostart method of providing a desktop item to start
    # xdg.configFile = {
    #   "autostart/OpenRGB.desktop".source = pkgs.makeDesktopItem {
    #     name = "OpenRGB";
    #     desktopName = "openrgb";
    #     genericName = "Control RGB lighting.";
    #     exec = "openrgb --startminimized --profile default";
    #     icon = "OpenRGB";
    #     type = "Application";
    #     categories = [ "Utility" ];
    #     terminal = false;
    #   };
    # };

    khanelinix.programs.graphical.wms.hyprland.startupCommands =
      let
        mkStartCommand = lib.khanelinix.uwsmApp osConfig;
        appCommands =
          # Regular applications (app-graphical.slice) - actively used, interactive
          (
            lib.optionals config.programs.firefox.enable [
              (mkStartCommand "${getExe config.programs.firefox.package}")
            ]
            # Background applications (background-graphical.slice) - communication clients, often idle
            ++ lib.optionals config.programs.vesktop.enable [
              (mkStartCommand { slice = "b"; } "${getExe config.programs.vesktop.package}")
            ]
            ++ lib.optionals (osConfig.programs.steam.enable or false) [
              (mkStartCommand { slice = "b"; } "${getExe osConfig.programs.steam.package}")
            ]
            ++ lib.optionals (config.khanelinix.suites.social.enable && socialIncludes "standard") [
              (mkStartCommand { slice = "b"; } "element-desktop")
            ]
            ++ lib.optionals (config.khanelinix.suites.business.enable && businessIncludes "standard") [
              (mkStartCommand { slice = "b"; } "teams-for-linux")
              (mkStartCommand { slice = "b"; } "thunderbird")
            ]
            # System services and utilities (background-graphical.slice)
            ++ lib.optionals (osConfig.services.hardware.openrgb.enable or false) [
              (mkStartCommand { slice = "b"; } "openrgb -c blue")
            ]
            ++ lib.optionals (osConfig.programs._1password-gui.enable or false) [
              (mkStartCommand { slice = "b"; } "1password --silent")
            ]
            ++ lib.optionals (osConfig.networking.networkmanager.enable or false) [
              (mkStartCommand { slice = "b"; } "nm-applet")
            ]
          )
          ++ [
            # Always start these utilities.
            (mkStartCommand { slice = "b"; } "wayvnc $(tailscale ip --4)")
          ];
      in
      lib.mkBefore (
        if (osConfig.programs.uwsm.enable or false) then [ "uwsm finalize" ] ++ appCommands else appCommands
      );
  };
}
