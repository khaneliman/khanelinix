{
  config,
  pkgs,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.emulators.warp;

in
{
  options.khanelinix.programs.terminal.emulators.warp = {
    enable = mkBoolOpt false "Whether or not to enable warp.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ warp-terminal ];

  };
}
