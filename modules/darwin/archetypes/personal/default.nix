{
  config,
  lib,
  khanelinix-lib,
  ...
}:
let
  inherit (khanelinix-lib) mkBoolOpt enabled;

  cfg = config.khanelinix.archetypes.personal;
in
{
  options.khanelinix.archetypes.personal = {
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
