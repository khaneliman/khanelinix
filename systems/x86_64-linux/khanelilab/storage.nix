{ lib, pkgs, ... }:
let
  xfsDataOptions = [
    "rw"
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
  # The parity filesystem must be provisioned separately. Never use the raw
  # Unraid parity device as a SnapRAID file or include it in mergerfs.
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

    "/mnt/parity" = {
      device = "/dev/disk/by-label/snapraid-parity";
      fsType = "xfs";
      options = xfsDataOptions;
    };

    "/mnt/user" = {
      device = "/mnt/disk1=RW:/mnt/disk2=RW:/mnt/disk3=RW:/mnt/disk4=RW:/mnt/cache=RW:/mnt/pool=RW";
      fsType = "fuse.mergerfs";
      options = [
        "allow_other"
        "use_ino"
        "inodecalc=path-hash"
        "never-forget-nodes=true"
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
        "x-systemd.requires-mounts-for=/mnt/parity"
      ];
    };
  };

  services.snapraid = {
    enable = true;
    dataDisks = {
      disk1 = "/mnt/disk1";
      disk2 = "/mnt/disk2";
      disk3 = "/mnt/disk3";
      disk4 = "/mnt/disk4";
    };
    parityFiles = [ "/mnt/parity/snapraid.parity" ];
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
      "/appdata/"
      "/domains/"
      "/system/"
    ];
    touchBeforeSync = false;
    sync.interval = "03:00";
    scrub = {
      interval = "Sun *-*-* 04:00:00";
      plan = 8;
      olderThan = 10;
    };
  };

  systemd.services = lib.genAttrs [ "snapraid-sync" "snapraid-scrub" ] (_: {
    unitConfig.RequiresMountsFor = [
      "/mnt/disk1"
      "/mnt/disk2"
      "/mnt/disk3"
      "/mnt/disk4"
      "/mnt/cache"
      "/mnt/pool"
      "/mnt/parity"
    ];
    # The first sync creates the parity file. Sandboxing its nonexistent file
    # path would fail before SnapRAID can initialize it.
    serviceConfig.ReadWritePaths = lib.mkForce [
      "/var/lib"
      "/mnt/disk1"
      "/mnt/disk2"
      "/mnt/disk3"
      "/mnt/disk4"
      "/mnt/cache"
      "/mnt/pool"
      "/mnt/parity"
    ];
  });

}
