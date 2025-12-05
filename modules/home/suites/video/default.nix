{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.video;
in
{
  options.khanelinix.suites.video = {
    enable = lib.mkEnableOption "video configuration";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      lib.optionals stdenv.hostPlatform.isLinux [
        celluloid
        devede
        handbrake
        kdePackages.k3b
        mediainfo-gui
        plex-desktop
        shotcut
        vlc
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ iina ];

    khanelinix = {
      programs = {
        graphical.apps = {
          obs.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
          mpv = lib.mkDefault enabled;
        };
      };
    };
  };
}
