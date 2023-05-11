{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.music;
in {
  options.khanelinix.suites.music = with types; {
    enable = mkBoolOpt false "Whether or not to enable music configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
        ardour = enabled;
        bottles = enabled;
        yt-music = enabled;
      };
    };
  };
}
