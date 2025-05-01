{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.archetypes.gaming;
in
{
  options.${namespace}.archetypes.gaming = {
    enable = lib.mkEnableOption "the gaming archetype";
  };

  config = mkIf cfg.enable {
    ${namespace}.suites = {
      common = enabled;
      desktop = enabled;
      games = enabled;
    };
  };
}
