{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps._1password;
in
{
  options.khanelinix.apps._1password = {
    enable = mkBoolOpt false "Whether or not to enable 1password.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      taps = [
        "1password/tap"
      ];

      casks = [
        "1password"
        "1password-cli"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "1Password for Safari" = 1569813296;
      };
    };
  };
}
