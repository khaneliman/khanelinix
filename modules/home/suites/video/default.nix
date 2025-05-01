{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.video;
in
{
  options.${namespace}.suites.video = {
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
        plex-media-player
        shotcut
        vlc
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [ iina ];

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
