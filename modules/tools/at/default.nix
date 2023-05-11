{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.at;
in {
  options.khanelinix.tools.at = with types; {
    enable = mkBoolOpt false "Whether or not to install at.";
    pkg = mkOpt package pkgs.khanelinix.at "The package to install as at.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.pkg
    ];
  };
}
