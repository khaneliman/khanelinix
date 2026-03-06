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
    editingEnable = lib.mkEnableOption "video editing applications";
    discEnable = lib.mkEnableOption "disc and physical media applications";
    broadcastingEnable = lib.mkEnableOption "broadcasting applications";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      lib.optionals cfg.editingEnable [
        mediainfo-gui
        mkvtoolnix
        self.packages.${system}.ff-title
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux (
        [
          celluloid
          plex-desktop
          vlc
        ]
        ++ lib.optionals cfg.editingEnable [
          # FIXME: remove qtwayland hard dependency
          shotcut
        ]
        ++ lib.optionals cfg.discEnable [
          # FIXME: broken on darwin due to mplayer dependency
          devede
          # FIXME: https://github.com/NixOS/nixpkgs/issues/484121
          # handbrake
          kdePackages.k3b
        ]
      )
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ iina ];

    khanelinix = {
      programs = {
        graphical.apps = {
          obs.enable = mkIf cfg.broadcastingEnable (lib.mkDefault pkgs.stdenv.hostPlatform.isLinux);
          mpv = lib.mkDefault enabled;
        };
      };
    };
  };
}
