{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.term;
in {
  options.khanelinix.desktop.addons.term = with types; {
    enable = mkBoolOpt false "Whether to install a terminal emulator.";
    pkg = mkOpt package pkgs.kitty "The terminal to install.";
  };

  config = mkIf cfg.enable {environment.systemPackages = [cfg.pkg];};
}
