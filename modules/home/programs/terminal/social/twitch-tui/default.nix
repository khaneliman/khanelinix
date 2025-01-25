{
  config,
  lib,
  khanelinix-lib,
  pkgs,
  root,
  osConfig,
  ...
}:
let
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.social.twitch-tui;
in
{
  options.khanelinix.programs.terminal.social.twitch-tui = {
    enable = mkBoolOpt false "Whether or not to enable twitch-tui.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.twitch-tui ];

    sops.secrets = lib.mkIf osConfig.khanelinix.security.sops.enable {
      twitch-tui = {
        sopsFile = khanelinix-lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/twt/config.toml";
      };
    };
  };
}
