{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.media;
in
{
  options.khanelinix.suites.media = with types; {
    enable = mkBoolOpt false "Whether or not to enable media configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      cli-apps = { cava = enabled; };
      apps = {
        ardour = enabled;
        yt-music = enabled;
      };
    };
  };
}
