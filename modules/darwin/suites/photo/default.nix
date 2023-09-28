{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.photo;
in
{
  options.khanelinix.suites.photo = {
    enable = mkBoolOpt false "Whether or not to enable photo configuration.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "digikam"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable { };
    };
  };
}
