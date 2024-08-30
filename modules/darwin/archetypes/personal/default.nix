{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.archetypes.personal;
in
{
  options.${namespace}.archetypes.personal = {
    enable = mkBoolOpt false "Whether or not to enable the personal archetype.";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      suites = {
        art = enabled;
        common = enabled;
        music = enabled;
        photo = enabled;
        social = enabled;
        video = enabled;
      };
    };
  };
}
