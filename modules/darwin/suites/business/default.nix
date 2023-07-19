{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.business;
in {
  options.khanelinix.suites.business = with types; {
    enable = mkBoolOpt false "Whether or not to enable business configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
    ];

    homebrew = {
      enable = true;

      masApps = {
        "1Password for Safari" = 1569813296;
        "Brother iPrint&Scan" = 1193539993;
        "Keynote" = 409183694;
        "Messenger" = 1480068668;
        "Microsoft OneNote" = 784801555;
        "Notability" = 360593530;
        "Numbers" = 409203825;
        "Pages" = 409201541;
        "Slack" = 803453959;
        "Telegram" = 747648890;
      };
    };

    khanelinix = {
      apps = {
      };
    };
  };
}
