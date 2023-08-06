{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.photo;
in
{
  options.khanelinix.suites.photo = with types; {
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
