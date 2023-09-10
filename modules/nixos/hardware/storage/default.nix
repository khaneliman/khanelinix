{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.hardware.storage;
in
{
  options.khanelinix.hardware.storage = {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for extra storage devices.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        ntfs3g
        fuseiso
        nfs-utils
        btrfs-progs
      ];
  };
}
