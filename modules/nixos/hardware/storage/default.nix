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

    # I/O Scheduler optimization for interactive latency
    hardware.block = {
      # NVMe: 'kyber' for latency-oriented scheduling under mixed workloads
      defaultScheduler = "kyber";
      # HDDs and SATA: BFQ provides better interactive latency
      defaultSchedulerRotational = "bfq";
      # Per-device overrides: SATA SSDs also benefit from BFQ
      scheduler = {
        "sd[a-z]" = "bfq";
      };
    };
  };
}
