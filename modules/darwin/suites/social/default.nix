{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.social;
in {
  options.khanelinix.suites.social = with types; {
    enable = mkBoolOpt false "Whether or not to enable social configuration.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;

      global = {
        brewfile = true;
      };

      casks = [
        "betterdiscord-installer"
        "caprine"
        "discord"
      ];

      masApps = {
        "Messenger" = 1480068668;
        "Slack" = 803453959;
        "Telegram" = 747648890;
      };
    };
  };
}
