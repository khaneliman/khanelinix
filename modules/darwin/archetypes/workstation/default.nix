{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.archetypes.workstation;
in
{
  options.khanelinix.archetypes.workstation = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable the workstation archetype.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      desktop.addons.barrier = enabled;

      suites = {
        business = enabled;
        common = enabled;
        desktop = enabled;
        development = enabled;
      };
    };
  };
}
