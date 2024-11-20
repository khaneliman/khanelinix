{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.archetypes.vm;
in
{
  options.khanelinix.archetypes.vm = {
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
