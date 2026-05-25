{ pkgs, ... }:
let
  dataDisks = {
    disk1 = "/mnt/disk1";
    disk2 = "/mnt/disk2";
    disk3 = "/mnt/disk3";
    disk4 = "/mnt/disk4";
  };

  xfsDataOptions = [
    "ro"
    "noatime"
    "nofail"
    "x-systemd.device-timeout=10s"
  ];

  btrfsPoolOptions = [
    "rw"
    "noatime"
    "ssd"
    "discard=async"
    "space_cache=v2"
    "nofail"
    "x-systemd.device-timeout=10s"
  ];
in
{
  # TODO: replace this Unraid-compatible layout with idiomatic NixOS/ZFS/Btrfs
  # mountpoints after khanelilab is stable and backups are verified.
  #
  # Existing Unraid inventory:
  # - /mnt/disk1..4 are XFS data disks behind Unraid md.
  # - /mnt/cache is the 1 TB NVMe Btrfs cache pool.
  # - /mnt/pool is the 2 TB SATA SSD Btrfs appdata pool.
  # - /mnt/user is Unraid shfs. NixOS approximates it with mergerfs.
  # - The 16 TB WDC WD160EDGZ disk appears to be parity; do not mount it.
  #
  # Quirks:
  # - This does not preserve Unraid's realtime md parity behavior.
  # - The XFS data disks are mounted read-only for first boot confidence.
  # - Writes through /mnt/user can only land on the writable cache/pool legs.
  # - SnapRAID parity is scheduled parity, not realtime parity. A restore can
  #   only recover the latest synced state.
  boot.supportedFilesystems = [
    "btrfs"
    "xfs"
  ];

  environment.systemPackages = with pkgs; [
    mergerfs
    xfsprogs
  ];

  fileSystems = {
    "/mnt/disk1" = {
      device = "/dev/disk/by-uuid/e4b2da7b-b31b-41d8-8f2d-11f053c4a3c9";
      fsType = "xfs";
      options = xfsDataOptions;
    };

    "/mnt/disk2" = {
      device = "/dev/disk/by-uuid/b0704a1e-6ec6-4b9c-8a5f-65dede2f8e55";
      fsType = "xfs";
      options = xfsDataOptions;
    };

    "/mnt/disk3" = {
      device = "/dev/disk/by-uuid/a9d261f5-80b5-41a9-bee7-05b04d6193c7";
      fsType = "xfs";
      options = xfsDataOptions;
    };

    "/mnt/disk4" = {
      device = "/dev/disk/by-uuid/9b8479c1-f4a0-4255-929d-15c4605cb682";
      fsType = "xfs";
      options = xfsDataOptions;
    };

    "/mnt/cache" = {
      device = "/dev/disk/by-uuid/8756807d-bbd8-42db-a06f-9960c280dffa";
      fsType = "btrfs";
      options = btrfsPoolOptions ++ [ "compress=zstd:3" ];
    };

    "/mnt/pool" = {
      device = "/dev/disk/by-uuid/3781f6b6-fbae-4fd2-9375-5c5f4d7ee0c7";
      fsType = "btrfs";
      options = btrfsPoolOptions;
    };

    "/mnt/user" = {
      device = "/mnt/disk1=RO:/mnt/disk2=RO:/mnt/disk3=RO:/mnt/disk4=RO:/mnt/cache=RW:/mnt/pool=RW";
      fsType = "fuse.mergerfs";
      options = [
        "allow_other"
        "use_ino"
        "cache.files=off"
        "dropcacheonclose=true"
        "category.create=epmfs"
        "moveonenospc=true"
        "minfreespace=50G"
        "fsname=mergerfs"
        "nofail"
        "x-systemd.requires-mounts-for=/mnt/disk1"
        "x-systemd.requires-mounts-for=/mnt/disk2"
        "x-systemd.requires-mounts-for=/mnt/disk3"
        "x-systemd.requires-mounts-for=/mnt/disk4"
        "x-systemd.requires-mounts-for=/mnt/cache"
        "x-systemd.requires-mounts-for=/mnt/pool"
      ];
    };
  };

  services.snapraid = {
    enable = true;

    inherit dataDisks;

    parityFiles = [
      "/dev/disk/by-id/ata-WDC_WD160EDGZ-11B2DA0_3FJ49DMT"
    ];

    contentFiles = [
      "/var/lib/snapraid.content"
      "/mnt/cache/snapraid.content"
      "/mnt/pool/snapraid.content"
    ];

    exclude = [
      "*.unrecoverable"
      "/.Trash-*/"
      "/.Recycle.Bin/"
      "/lost+found/"
      "/tmp/"
    ];

    # Data disks are intentionally read-only during first migration boot, so do
    # not let SnapRAID update mtimes before sync.
    touchBeforeSync = false;

    sync.interval = "03:00";

    scrub = {
      interval = "Sun *-*-* 04:00:00";
      plan = 8;
      olderThan = 10;
    };
  };

  systemd.services.snapraid-sync = {
    after = [
      "mnt-disk1.mount"
      "mnt-disk2.mount"
      "mnt-disk3.mount"
      "mnt-disk4.mount"
      "mnt-cache.mount"
      "mnt-pool.mount"
    ];

    requires = [
      "mnt-disk1.mount"
      "mnt-disk2.mount"
      "mnt-disk3.mount"
      "mnt-disk4.mount"
      "mnt-cache.mount"
      "mnt-pool.mount"
    ];
  };
}
