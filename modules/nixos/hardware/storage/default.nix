{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.hardware.storage;
in
{
  options.khanelinix.hardware.storage = {
    enable = lib.mkEnableOption "support for extra storage devices";
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
