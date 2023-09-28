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
    environment.systemPackages = with pkgs; [
      armcord
      caprine-bin
      element-desktop
      slack
      slack-term
      telegram-desktop
    ];

    khanelinix = {
      apps = {
        # TODO: switch to armcord ? 
        discord = enabled;
      };
    };
  };
}
