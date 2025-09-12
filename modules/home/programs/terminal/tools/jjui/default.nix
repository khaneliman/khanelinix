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
      enable = true;

      settings = {
        limit = 0;

        custom_commands = {
          "show all commits" = {
            key = [ "a" ];
            revset = "all()";
          };
          "show default view" = {
            key = [ "d" ];
            revset = "";
          };
          "edit immutable" = {
            key = [ "e" ];
            args = [
              "edit"
              "--ignore-immutable"
              "-r"
              "$change_id"
            ];
          };
          "squash immutable" = {
            key = [ "s" ];
            args = [
              "squash"
              "--ignore-immutable"
              "-r"
              "$change_id"
            ];
          };
        };

        preview = {
          show_at_start = true;
          width_percentage = 60.0;
        };

        oplog = {
          limit = 500;
        };

        graph = {
          batch_size = 100;
        };
      };
    };
  };
}
