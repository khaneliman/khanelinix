{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.atuin;
in
{
  options.khanelinix.programs.terminal.tools.atuin = {
    enable = lib.mkEnableOption "atuin";
    enableDebug = lib.mkEnableOption "atuin daemon debug logging";
  };

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      daemon =
        {
          enable = true;
        }
        // lib.optionalAttrs cfg.enableDebug {
          logLevel = "debug";
        };

      # flags = [
      #   "--disable-up-arrow"
      # ];

      settings = {
        enter_accept = true;
        # Filter modes can still be toggled via `ctrl-r`
        filter_mode = "workspace";
        keymap_mode = "auto";
        show_preview = true;
        # NOTE: Whether to store commands that failed.
        # Can be useful to auto prune, but lose commands that might have
        # a simple typo to fix and would need to type again.
        # store_failed = false;
        style = "auto";
        update_check = false;
        workspaces = true;

        # Filter some commands we don't want to accidentally call from history
        history_filter = [
          "^(sudo reboot)$"
          "^(reboot)$"
        ];
      };
    };
  };
}
