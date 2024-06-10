{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.emulators.warp;

in
{
  options.${namespace}.programs.terminal.emulators.warp = {
    enable = mkBoolOpt false "Whether or not to enable warp.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ warp-terminal ];

  };
}
