{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.archetypes.server;
in
{
  options.${namespace}.archetypes.server = {
    enable = mkBoolOpt false "Whether or not to enable the server archetype.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      suites = {
        common = enabled;
      };
    };
  };
}
