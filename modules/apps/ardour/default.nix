{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.ardour;
in {
  options.khanelinix.apps.ardour = with types; {
    enable = mkBoolOpt false "Whether or not to enable Ardour.";
  };

  config =
    mkIf cfg.enable {environment.systemPackages = with pkgs; [ardour];};
}
