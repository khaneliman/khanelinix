{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.music;
in {
  options.khanelinix.suites.music = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common music configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      cli-apps = {
        ncmpcpp = enabled;
      };

      services = {
        mpd = enabled;
      };
    };
  };
}
