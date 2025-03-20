{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.archetypes.server;
in
{
  options.${namespace}.archetypes.server = {
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
