{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.git-crypt;
in
{
  options.khanelinix.programs.terminal.tools.git-crypt = {
    enable = lib.mkEnableOption "git-crypt";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ git-crypt ]; };
}
