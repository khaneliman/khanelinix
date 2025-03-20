{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.git-crypt;
in
{
  options.${namespace}.programs.terminal.tools.git-crypt = {
    enable = lib.mkEnableOption "git-crypt";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ git-crypt ]; };
}
