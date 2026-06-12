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
  inherit (lib.khanelinix) enabled mkPackageProfileOption;

  cfg = config.khanelinix.suites.video;
in
{
  options.khanelinix.suites.video = {
    enable = lib.mkEnableOption "video configuration";
    packageProfile = mkPackageProfileOption "Package profile override for video applications.";
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
          devede
          handbrake
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
