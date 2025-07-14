{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let

  cfg = config.khanelinix.programs.terminal.social.twitch-tui;
in
{
  options.khanelinix.programs.terminal.social.twitch-tui = {
    enable = lib.mkEnableOption "twitch-tui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.twitch-tui ];

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      twitch-tui = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/twt/config.toml";
      };
    };
  };
}
