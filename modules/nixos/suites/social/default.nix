{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.social;
in
{
  options.khanelinix.suites.social = with types; {
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
        discord = {
          enable = true;
        };
      };
    };
  };
}
