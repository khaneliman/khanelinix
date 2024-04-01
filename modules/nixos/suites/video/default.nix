{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.video;
in
{
  options.khanelinix.suites.video = {
    enable = mkBoolOpt false "Whether or not to enable video configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      devede
      # FIX: broken nixpkgs
      # handbrake
      mediainfo-gui
      pitivi
      vlc
    ];

    # NOTE: dvd burning software requires cdrom group and k3b dependencies in nix store do not have those permissions
    # https://github.com/NixOS/nixpkgs/issues/19154#issuecomment-647005545
    # Additionally to installing `k3b` enabling this will
    # add `setuid` wrappers in `/run/wrappers/bin`
    # for both `cdrdao` and `cdrecord`. On first
    # run you must manually configure the path of `cdrdae` and
    # `cdrecord` to correspond to the appropriate paths under
    # `/run/wrappers/bin` in the "Setup External Programs" menu.
    programs.k3b.enable = true;

    khanelinix = {
      user.extraGroups = [ "cdrom" ];
    };
  };
}
