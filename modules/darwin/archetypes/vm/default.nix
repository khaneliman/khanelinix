{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.archetypes.vm;
in
{
  options.khanelinix.archetypes.vm = {
    enable = lib.mkEnableOption "the vm archetype";
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
