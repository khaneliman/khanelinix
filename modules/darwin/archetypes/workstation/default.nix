{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.archetypes.workstation;
in
{
  options.${namespace}.archetypes.workstation = {
    enable = mkBoolOpt false "Whether or not to enable the workstation archetype.";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      # TODO: input-leap replace barrier

      suites = {
        business = enabled;
        common = enabled;
        desktop = enabled;
        development = enabled;
      };
    };
  };
}
