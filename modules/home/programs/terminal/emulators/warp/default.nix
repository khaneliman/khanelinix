{
  config,
  pkgs,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.emulators.warp;

in
{
  options.khanelinix.programs.terminal.emulators.warp = {
    enable = lib.mkEnableOption "warp";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ warp-terminal ];

  };
}
