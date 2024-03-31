{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.social;
in
{
  options.khanelinix.suites.social = {
    enable = mkBoolOpt false "Whether or not to enable social configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      slack-term
    ];

    khanelinix = {
      apps = {
        # armcord = enabled;
        discord = enabled;
        caprine = enabled;
      };

      cli-apps = {
        twitch-tui = enabled;
      };
    };
  };
}
