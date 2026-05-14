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
        workspace_rule =
          lib.optionals cfg.smartGaps.enable [
            # Smart gaps: remove gaps when a normal workspace has one tiled window or one fullscreen window.
            {
              workspace = "w[tv1]s[false]";
              gaps_in = 0;
              gaps_out = 0;
            }
            {
              workspace = "f[1]s[false]";
              gaps_in = 0;
              gaps_out = 0;
            }
          ]
          ++ [
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

        window_rule = lib.mkIf cfg.smartGaps.enable [
          {
            match.float = false;
            match.workspace = "w[tv1]s[false]";
            border_size = 0;
            rounding = 0;
          }
          {
            match.float = false;
            match.workspace = "f[1]s[false]";
            border_size = 0;
            rounding = 0;
          }
        ];
      };
    };
  };
}
