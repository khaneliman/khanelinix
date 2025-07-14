{
  config,
  lib,
  pkgs,

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
          (map mkStartCommand [
            "${getExe config.programs.firefox.package}"
            "${getExe pkgs.steam}"
            "${getExe config.programs.vesktop.package}"
            "${getExe pkgs.element-desktop}"
            "${getExe pkgs.teams-for-linux}"
            "${getExe pkgs.thunderbird}"
            "${getExe pkgs.openrgb-with-all-plugins} -c blue"
            "${getExe pkgs._1password-gui} --silent"
            "${getExe pkgs.tailscale-systray}"
            "${getExe pkgs.networkmanagerapplet}"
            "${getExe pkgs.wl-clip-persist} --clipboard both"
            "$(${getExe pkgs.wayvnc} $(${getExe pkgs.tailscale} ip --4))"
          ])
          ++ lib.optionals (osConfig.programs.uwsm.enable or false) [ "uwsm finalize" ];
      };
    };
  };
}
