{
  config,
  lib,
  pkgs,
  self,
  system,
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
      [ self.packages.${system}.ff-title ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        celluloid
        devede
        # FIXME: https://github.com/NixOS/nixpkgs/issues/484121
        # handbrake
        kdePackages.k3b
        mediainfo-gui
        mkvtoolnix
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
