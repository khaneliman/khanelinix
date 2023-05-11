{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.archetypes.vm;
in {
  options.khanelinix.archetypes.vm = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable the vm archetype.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      suites = {
        common-slim = enabled;
        desktop = enabled;
        development = enabled;
        vm = enabled;
      };

      tools = {
        appimage-run = enabled;
      };
    };
  };
}
