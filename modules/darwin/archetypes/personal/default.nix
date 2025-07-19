{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.archetypes.personal;
in
{
  options.khanelinix.archetypes.personal = {
    enable = lib.mkEnableOption "the personal archetype";
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
