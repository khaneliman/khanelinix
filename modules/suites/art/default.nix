{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.art;
in {
  options.khanelinix.suites.art = with types; {
    enable = mkBoolOpt false "Whether or not to enable art configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
        gimp = enabled;
        inkscape = enabled;
        blender = enabled;
      };
    };
  };
}
