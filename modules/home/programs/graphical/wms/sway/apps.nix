{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.${namespace}.programs.graphical.wms.hyprland;
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
        exec-once = [
          # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
          # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
          # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

          # Startup apps that have rules for organizing them
          "${getExe config.programs.firefox.package}"
          "${getExe pkgs.steam}"
          "${getExe pkgs.discord}"
          "${getExe pkgs.thunderbird}"

          # Startup background apps
          "${getExe pkgs.openrgb-with-all-plugins} --startminimized --profile default"
          "${getExe pkgs._1password-gui} --silent"
          "${getExe pkgs.tailscale-systray}"
          "run-as-service $(${getExe pkgs.wayvnc} $(${getExe pkgs.tailscale} ip --4))"
        ];
      };
    };
  };
}
