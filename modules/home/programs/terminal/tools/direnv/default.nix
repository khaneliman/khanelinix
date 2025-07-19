{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.programs.terminal.tools.direnv;
in
{
  options.khanelinix.programs.terminal.tools.direnv = {
    enable = lib.mkEnableOption "direnv";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = enabled;
      silent = true;
    };
  };
}
