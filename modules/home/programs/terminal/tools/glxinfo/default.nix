{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.glxinfo;
in
{
  options.khanelinix.programs.terminal.tools.glxinfo = {
    enable = mkBoolOpt false "Whether or not to enable glxinfo.";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ glxinfo ]; };
}
