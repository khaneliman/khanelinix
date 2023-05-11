{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.feh;
in {
  options.khanelinix.cli-apps.feh = with types; {
    enable = mkBoolOpt false "Whether or not to enable feh.";
  };

  config =
    mkIf cfg.enable {environment.systemPackages = with pkgs; [feh];};
}
