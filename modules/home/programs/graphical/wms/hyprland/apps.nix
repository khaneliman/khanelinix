{
  config,
  lib,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;
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

    wayland.windowManager.hyprland = {
      settings = {
        exec-once =
          let
            # Helper function to conditionally prefix with uwsm
            mkStartCommand =
              cmd: if (osConfig.programs.uwsm.enable or false) then "uwsm app -- ${cmd}" else cmd;
          in
          # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
          # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
          # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

          # Startup apps that have rules for organizing them
          (map mkStartCommand (
            lib.optionals config.programs.firefox.enable [
              "${getExe config.programs.firefox.package}"
            ]
            ++ lib.optionals config.programs.vesktop.enable [
              "${getExe config.programs.vesktop.package}"
            ]
            ++ lib.optionals (osConfig.programs.steam.enable or false) [
              "steam"
            ]
            ++ lib.optionals config.khanelinix.suites.social.enable [
              "element-desktop"
            ]
            ++ lib.optionals config.khanelinix.suites.business.enable [
              "teams-for-linux"
              "thunderbird"
            ]
            ++ lib.optionals (osConfig.services.hardware.openrgb.enable or false) [
              "openrgb -c blue"
            ]
            ++ lib.optionals (osConfig.programs._1password-gui.enable or false) [
              "1password --silent"
            ]
            ++ lib.optionals (osConfig.services.tailscale.enable or false) [
              "tailscale-systray"
            ]
            ++ lib.optionals (osConfig.networking.networkmanager.enable or false) [
              "nm-applet"
            ]
            ++ [
              # Always start these utilities
              "wl-clip-persist --clipboard both"
              "wayvnc $(tailscale ip --4)"
            ]
          ))
          ++ lib.optionals (osConfig.programs.uwsm.enable or false) [ "uwsm finalize" ];
      };
    };
  };
}
