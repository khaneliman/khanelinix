{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.social;
in
{
  options.${namespace}.suites.social = {
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
