{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe getExe';

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
          "command -v ${getExe pkgs.cliphist} && ${getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch cliphist store" # Stores only text data
          "command -v ${getExe pkgs.cliphist} && ${getExe' pkgs.wl-clipboard "wl-paste"} --type image --watch cliphist store" # Stores only image data

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
