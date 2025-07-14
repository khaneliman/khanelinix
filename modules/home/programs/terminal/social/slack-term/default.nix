{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.social.slack-term;
in
{
  options.khanelinix.programs.terminal.social.slack-term = {
    enable = lib.mkEnableOption "slack-term";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.slack-term ];

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      slack-term = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/slack-term/config";
      };
    };
  };
}
