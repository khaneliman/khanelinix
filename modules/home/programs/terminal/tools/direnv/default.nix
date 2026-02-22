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
      # Direnv configuration
      # See: https://direnv.net/
      enable = true;
      nix-direnv = enabled;
      silent = true;
    };
  };
}
