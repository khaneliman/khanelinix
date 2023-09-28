{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.music;
in
{
  options.khanelinix.suites.music = {
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
