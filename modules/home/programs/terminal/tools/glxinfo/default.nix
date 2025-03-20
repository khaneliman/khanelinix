{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.glxinfo;
in
{
  options.${namespace}.programs.terminal.tools.glxinfo = {
    enable = lib.mkEnableOption "glxinfo";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ glxinfo ]; };
}
