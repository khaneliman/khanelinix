{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.video;
in
{
  options.khanelinix.suites.video = {
    enable = mkBoolOpt false "Whether or not to enable video configuration.";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      lib.optionals stdenv.isLinux [
        devede
        handbrake
        mediainfo-gui
        shotcut
        vlc
      ];

    khanelinix = {
      programs = {
        graphical.apps = {
          obs = enabled;
        };
      };
    };
  };
}
