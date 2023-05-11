{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.onefetch;
in {
  options.khanelinix.cli-apps.onefetch = with types; {
    enable = mkBoolOpt false "Whether or not to enable onefetch.";
  };

  config =
    mkIf cfg.enable {environment.systemPackages = with pkgs; [onefetch];};
}
