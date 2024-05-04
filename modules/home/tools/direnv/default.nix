{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.tools.direnv;
in
{
  options.khanelinix.tools.direnv = {
    enable = mkBoolOpt false "Whether or not to enable direnv.";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      DIRENV_LOG_FORMAT = "";
    };

    programs.direnv = {
      enable = true;
      nix-direnv = enabled;
    };
  };
}
