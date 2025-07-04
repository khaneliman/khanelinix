{
  config,
  lib,
  pkgs,
  namespace,
  osConfig ? { },
  ...
}:
let

  cfg = config.${namespace}.programs.terminal.social.twitch-tui;
in
{
  options.${namespace}.programs.terminal.social.twitch-tui = {
    enable = lib.mkEnableOption "twitch-tui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.twitch-tui ];

    sops.secrets = lib.mkIf (osConfig.${namespace}.security.sops.enable or false) {
      twitch-tui = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/twt/config.toml";
      };
    };
  };
}
