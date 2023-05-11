{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.social;
in {
  options.khanelinix.suites.social = with types; {
    enable = mkBoolOpt false "Whether or not to enable social configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
        discord = {
          enable = true;
          chromium = enabled;
        };
      };
    };
  };
}
