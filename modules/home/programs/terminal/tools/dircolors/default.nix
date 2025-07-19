{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.dircolors;
in
{
  options.khanelinix.programs.terminal.tools.dircolors = {
    enable = lib.mkEnableOption "dircolors";
  };

  config = mkIf cfg.enable {
    programs.dircolors = {
      enable = true;
    };
  };
}
