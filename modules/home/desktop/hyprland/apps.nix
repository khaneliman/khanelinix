{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.hyprland;
in {
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
            "command -v hyprpaper && hyprpaper"
            "command -v ckb-next && ckb-next -b"
            "command -v openrgb && openrgb --startminimized --profile default"
            "command -v 1password && 1password --silent"
            "command -v mpd-mpris && mpd-mpris"
            "command -v cliphist && wl-paste --type text --watch cliphist store" #Stores only text data
            "command -v cliphist && wl-paste --type image --watch cliphist store" #Stores only image data

            # Startup apps that have rules for organizing them
            "[workspace special silent ] kitty --session scratchpad" # Spawn scratchpad terminal
            "command -v firefox && firefox"
            "command -v steam && steam"
            "command -v discord && discord"
            "command -v thunderbird && thunderbird"

            "command -v virt-manager && virt-manager"
          ];
        };
      };
    };
}
