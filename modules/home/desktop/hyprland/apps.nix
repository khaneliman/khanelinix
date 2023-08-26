{ config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.hyprland;
in
{
  config =
    mkIf cfg.enable
      {
        wayland.windowManager.hyprland = {
          settings = {
            exec-once = [
              # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
              # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
              # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

              # Startup background apps
              "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1 &"
              "${lib.getExe pkgs.hyprpaper}"
              "${lib.getExe pkgs.ckb-next} -b"
              "${lib.getExe pkgs.openrgb} --startminimized --profile default"
              "${lib.getExe pkgs._1password-gui} --silent"
              "command -v cliphist && wl-paste --type text --watch cliphist store" #Stores only text data
              "command -v cliphist && wl-paste --type image --watch cliphist store" #Stores only image data

              # Startup apps that have rules for organizing them
              "[workspace special silent ] ${lib.getExe pkgs.kitty} --session scratchpad" # Spawn scratchpad terminal
              "${lib.getExe pkgs.firefox}"
              "${lib.getExe pkgs.steam}"
              "${lib.getExe pkgs.discord}"
              "${lib.getExe pkgs.thunderbird}"

              "${lib.getExe pkgs.virt-manager}"
            ];
          };
        };
      };
}
