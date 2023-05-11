{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.video;
in {
  options.khanelinix.suites.video = with types; {
    enable = mkBoolOpt false "Whether or not to enable video configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
        pitivi = enabled;
        obs = enabled;
      };
    };
  };
}
