{
  config,
  khanelinix-lib,
  lib,
  osConfig,
  pkgs,
  root,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.social.slack-term;
in
{
  options.khanelinix.programs.terminal.social.slack-term = {
    enable = mkBoolOpt false "Whether or not to enable slack-term.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.slack-term ];

    sops.secrets = lib.mkIf osConfig.khanelinix.security.sops.enable {
      slack-term = {
        sopsFile = root + "/secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/slack-term/config";
      };
    };
  };
}
