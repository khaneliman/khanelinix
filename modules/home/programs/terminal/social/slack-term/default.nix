{
  config,
  lib,
  pkgs,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.social.slack-term;
in
{
  options.${namespace}.programs.terminal.social.slack-term = {
    enable = mkBoolOpt false "Whether or not to enable slack-term.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.slack-term ];

    sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
      slack-term = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/slack-term/config";
      };
    };
  };
}
