{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        exec-once = [
          # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
          # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
          # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

          # Startup background apps
          "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1 &"
          "${getExe pkgs.openrgb} --startminimized --profile default"
          "${getExe pkgs._1password-gui} --silent"

          # Startup apps that have rules for organizing them
          "${getExe pkgs.firefox}"
          "${getExe pkgs.steam}"
          "${getExe pkgs.discord}"
          "${getExe pkgs.thunderbird}"
          "${getExe pkgs.virt-manager}"
        ];
      };
    };
  };
}
