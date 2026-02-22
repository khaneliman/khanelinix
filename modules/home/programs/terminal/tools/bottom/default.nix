{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.bottom;
in
{
  options.khanelinix.programs.terminal.tools.bottom = {
    enable = lib.mkEnableOption "bottom";
  };

  config = mkIf cfg.enable {
    programs.bottom = {
      enable = true;
      package = pkgs.bottom;

      # Bottom configuration
      # See: https://github.com/ClementTsang/bottom#configuration
      settings = {
        flags.group_processes = true;

        row = [
          {
            ratio = 3;
            child = [
              { type = "cpu"; }
              { type = "mem"; }
              { type = "net"; }
            ];
          }
          {
            ratio = 3;
            child = [
              {
                type = "proc";
                ratio = 1;
                default = true;
              }
            ];
          }
        ];
      };
    };
  };
}
