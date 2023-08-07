{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.art;
in
{
  options.khanelinix.suites.art = with types; {
    enable = mkBoolOpt false "Whether or not to enable art configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
        blender = enabled;
        gimp = enabled;
        inkscape = enabled;
      };
    };
  };
}
