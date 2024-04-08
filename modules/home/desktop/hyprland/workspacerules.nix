{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        workspace = [
          ##
          # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀░░░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀
          # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀░░░█░░░█░█░█░█░█▀▀░░█░░█░█
          # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀
          ##

          # Code
          "3, on-created-empty:$term tmux a"
          # Gaming
          "4, on-created-empty:steam"
          # Messaging
          "5, on-created-empty:discord"
          # Mail
          "6, on-created-empty:thunderbird"
          #Remote
          "8, on-created-empty:virt-manager"

          "special:scratchpad, on-created-empty:$term"
        ];
      };
    };
  };
}
