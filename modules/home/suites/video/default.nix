{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt enabled;

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
        celluloid
        # FIXME: broken nixpkgs
        # devede
        handbrake
        mediainfo-gui
        # FIXME: broken nixpkgs
        # shotcut
        vlc
      ]
      ++ lib.optionals stdenv.isDarwin [ iina ];

    khanelinix = {
      programs = {
        graphical.apps = {
          obs = lib.mkDefault enabled;
          mpv = lib.mkDefault enabled;
        };
      };
    };
  };
}
