{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.suites.video;
in
{
  options.khanelinix.suites.video = {
    enable = mkBoolOpt false "Whether or not to enable video configuration.";
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
