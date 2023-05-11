{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.archetypes.gaming;
in {
  options.khanelinix.archetypes.gaming = with types; {
    enable = mkBoolOpt false "Whether or not to enable the gaming archetype.";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      common = enabled;
      desktop = enabled;
      games = enabled;
      social = enabled;
      media = enabled;
    };
  };
}
