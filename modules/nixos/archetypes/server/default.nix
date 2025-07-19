{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.archetypes.server;
in
{
  options.khanelinix.archetypes.server = {
    enable = lib.mkEnableOption "the server archetype";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      suites = {
        common = enabled;
      };
    };
  };
}
