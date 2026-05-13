{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        workspace_rule = [
          ##
          # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀░░░█▀▀░█▀█░█▀█░█▀▀░▀█▀░█▀▀
          # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀░░░█░░░█░█░█░█░█▀▀░░█░░█░█
          # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░░▀▀▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀▀
          ##

          # Code
          {
            workspace = "3";
            on_created_empty = "kitty zellij";
          }
          # Gaming
          {
            workspace = "4";
            on_created_empty = "steam";
          }
          # Messaging
          {
            workspace = "5";
            on_created_empty = "discord";
          }
          # Mail
          {
            workspace = "6";
            on_created_empty = "thunderbird";
          }

          {
            workspace = "special:scratchpad";
            on_created_empty = "kitty";
          }
        ];
      };
    };
  };
}
