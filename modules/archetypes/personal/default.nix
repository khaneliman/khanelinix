{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.archetypes.personal;
in
{
  options.khanelinix.archetypes.personal = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable the personal archetype.";
  };

  config = mkIf cfg.enable {
    khanelinix = {

      apps = { agenix = enabled; };
      suites = { };

      tools = {
        appimage-run = enabled;
      };
    };
  };
}
