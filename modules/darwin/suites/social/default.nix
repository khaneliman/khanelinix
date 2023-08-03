{ options
, config
, lib
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
    homebrew = {
      casks = [
        "betterdiscord-installer"
        "caprine"
        "discord"
        "element"
        "slack"
        "telegram"
      ];
    };
  };
}
