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
    wayland.windowManager.hyprland = {
      settings = {
        exec-once = [
          # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
          # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
          # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

          # Startup apps that have rules for organizing them
          "${getExe pkgs.firefox}"
          "${getExe pkgs.steam}"
          "${getExe pkgs.discord}"
          "${getExe pkgs.thunderbird}"
          "${getExe pkgs.virt-manager}"

          # Startup background apps
          "${getExe pkgs.openrgb} --startminimized --profile default"
          "${getExe pkgs._1password-gui} --silent"
        ];
      };
    };
  };
}
