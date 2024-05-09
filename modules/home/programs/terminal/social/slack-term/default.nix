{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.social.slack-term;
in
{
  options.khanelinix.programs.terminal.social.slack-term = {
    enable = mkBoolOpt false "Whether or not to enable slack-term.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.slack-term ];

    sops.secrets = {
      slack-term = {
        sopsFile = ../../../../../../secrets/khaneliman/default.yaml;
        path = "${config.home.homeDirectory}/.config/slack-term/config";
      };
    };
  };
}
