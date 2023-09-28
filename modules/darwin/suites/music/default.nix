{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.music;
in
{
  options.khanelinix.suites.music = {
    enable = mkBoolOpt false "Whether or not to enable music configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      spicetify-cli
      spotify-tui
      youtube-dl
    ];

    homebrew = {
      casks = [
        "spotify"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "GarageBand" = 682658836;
      };
    };
  };
}
