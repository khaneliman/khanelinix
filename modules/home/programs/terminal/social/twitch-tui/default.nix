{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.social.twitch-tui;
in
{
  options.${namespace}.programs.terminal.social.twitch-tui = {
    enable = mkBoolOpt false "Whether or not to enable twitch-tui.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.twitch-tui ];

    sops.secrets = {
      twitch-tui = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/twt/config.toml";
      };
    };
  };
}
