{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.archetypes.vm;
in
{
  options.${namespace}.archetypes.vm = {
    enable = mkBoolOpt false "Whether or not to enable the vm archetype.";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      suites = {
        common = enabled;
        desktop = enabled;
        development = enabled;
        vm = enabled;
      };
    };
  };
}
