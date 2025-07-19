{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.glxinfo;
in
{
  options.khanelinix.programs.terminal.tools.glxinfo = {
    enable = lib.mkEnableOption "glxinfo";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ glxinfo ]; };
}
