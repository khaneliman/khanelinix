{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.video;
in
{
  options.khanelinix.suites.video = {
    enable = lib.mkEnableOption "video configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ffmpeg ];

    homebrew = {
      casks = [
        "plex"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "Infuse" = 1136220934;
        "iMovie" = 408981434;
      };
    };
  };
}
