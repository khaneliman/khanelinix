{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.twitch-tui;
in
{
  options.khanelinix.cli-apps.twitch-tui = {
    enable = mkBoolOpt false "Whether or not to enable twitch-tui.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.twitch-tui ];

    sops.secrets = {
      twitch-tui = {
        sopsFile = ../../../../secrets/khaneliman/default.yaml;
        path = "${config.home.homeDirectory}/.config/twt/config.toml";
      };
    };
  };
}
