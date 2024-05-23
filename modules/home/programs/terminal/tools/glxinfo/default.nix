{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.glxinfo;
in
{
  options.${namespace}.programs.terminal.tools.glxinfo = {
    enable = mkBoolOpt false "Whether or not to enable glxinfo.";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ glxinfo ]; };
}
