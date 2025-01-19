{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.hardware.storage;
in
{
  imports = [
    ./btrfs
    ./zfs
  ];

  options.khanelinix.hardware.storage = {
    enable = mkBoolOpt false "Whether or not to enable support for extra storage devices.";
    ssdEnable = mkBoolOpt true "Whether or not to enable support for SSD storage devices.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      btrfs-progs
      fuseiso
      nfs-utils
      ntfs3g
    ];

    services.fstrim.enable = lib.mkDefault cfg.ssdEnable;
  };
}
