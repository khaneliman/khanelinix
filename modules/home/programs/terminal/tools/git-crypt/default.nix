{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.git-crypt;
in
{
  options.khanelinix.programs.terminal.tools.git-crypt = {
    enable = mkBoolOpt false "Whether or not to enable git-crypt.";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ git-crypt ]; };
}
