{
  config,
  lib,
  pkgs,
  root,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

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
