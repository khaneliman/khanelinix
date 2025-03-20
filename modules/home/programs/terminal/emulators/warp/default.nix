{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.emulators.warp;

in
{
  options.${namespace}.programs.terminal.emulators.warp = {
    enable = lib.mkEnableOption "warp";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ warp-terminal ];

  };
}
