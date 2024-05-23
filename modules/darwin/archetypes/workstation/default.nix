{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.archetypes.workstation;
in
{
  options.${namespace}.archetypes.workstation = {
    enable = mkBoolOpt false "Whether or not to enable the workstation archetype.";
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
