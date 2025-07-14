{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.archetypes.gaming;
in
{
  options.khanelinix.archetypes.gaming = {
    enable = lib.mkEnableOption "the gaming archetype";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      common = enabled;
      desktop = enabled;
      games = enabled;
    };
  };
}
