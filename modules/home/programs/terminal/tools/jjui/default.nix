{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.jjui;
in
{
  options.khanelinix.programs.terminal.tools.jjui = {
    enable = lib.mkEnableOption "jjui";
  };

  config = mkIf cfg.enable {
    programs.jjui = {
      # Jjui documentation
      # See: https://github.com/idursun/jjui
      enable = true;

      settings = {
        limit = 0;

        inherit (import ./custom-commands.nix) actions bindings;

        preview = {
          show_at_start = true;
          width_percentage = 60.0;
        };

        oplog = {
          limit = 500;
        };

        revisions = {
          log_batch_size = 100;
        };
      };
    };
  };
}
