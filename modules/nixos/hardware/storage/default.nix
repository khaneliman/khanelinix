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
    disableUsbAutoSuspend = mkBoolOpt false "Disable USB autosuspend to prevent USB device lag.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      btrfs-progs
      fuseiso
      nfs-utils
      ntfs3g
      nvme-cli
    ];

    services.fstrim.enable = lib.mkDefault cfg.ssdEnable;

    # NVMe power management: allow deeper power states but limit latency
    # Default is 25000us (25ms) - we use 100us for low-latency desktop
    boot.kernelParams =
      lib.optionals cfg.ssdEnable [
        "nvme_core.default_ps_max_latency_us=100"
      ]
      ++ lib.optionals cfg.disableUsbAutoSuspend [
        "usbcore.autosuspend=-1"
      ];

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

    # Storage device tuning via udev
    services.udev.extraRules = lib.concatStringsSep "\n" (
      lib.optionals cfg.ssdEnable [
        # NVMe: Optimize queue depth and read-ahead for low latency
        # Note: udev KERNEL globs are not regex; without excluding partitions
        # this also matches e.g. nvme0n1p1 (and partitions don't always expose
        # queue/* attributes), causing noisy udev-worker errors.
        ''ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", KERNEL!="*p*", ATTR{queue/nr_requests}="32"''
        ''ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", KERNEL!="*p*", ATTR{queue/read_ahead_kb}="128"''
        # SATA SSD: Moderate read-ahead, higher queue depth
        ''ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/read_ahead_kb}="256"''
        ''ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/nr_requests}="64"''
        # HDD: Higher read-ahead for sequential performance
        ''ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/read_ahead_kb}="1024"''
        ''ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/nr_requests}="256"''
      ]
    );
  };
}
