{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.bottom;
in
{
  options.khanelinix.programs.terminal.tools.bottom = {
    enable = mkBoolOpt false "Whether or not to enable bottom.";
  };

  config = mkIf cfg.enable {
    programs.bottom = {
      enable = true;
      package = pkgs.bottom;
    };
  };
}
