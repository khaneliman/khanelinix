{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.gparted;
in {
  options.khanelinix.apps.gparted = with types; {
    enable = mkBoolOpt false "Whether or not to enable gparted.";
  };

  config =
    mkIf cfg.enable {environment.systemPackages = with pkgs; [gparted];};
}
