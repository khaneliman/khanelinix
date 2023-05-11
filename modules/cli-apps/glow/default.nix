{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.glow;
in {
  options.khanelinix.cli-apps.glow = with types; {
    enable = mkBoolOpt false "Whether or not to enable glow.";
  };

  config =
    mkIf cfg.enable {environment.systemPackages = with pkgs; [glow];};
}
