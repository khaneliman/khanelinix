{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.archetypes.personal;
in
{
  options.${namespace}.archetypes.personal = {
    enable = lib.mkEnableOption "the personal archetype";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      services = {
        tailscale = enabled;
      };

      suites = {
        common = enabled;
      };
    };
  };
}
