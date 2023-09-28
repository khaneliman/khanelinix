{ pkgs
, modulesPath
, inputs
, ...
}:
let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    common-cpu-amd
    common-gpu-amd
    # NOTE: actually removes gpu from list of devices now so can't use GPU-passthru
    # common-gpu-nvidia-disable
    common-pc
    common-pc-ssd
  ];

  ##
  # Desktop VM config
  ##
  boot = {
    blacklistedKernelModules = [
      "eeepc_wmi"
    ];

    # consoleLogLevel = 0;

    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl."kernel.sysrq" = 1;
    kernelParams = [
      "video=DP-1:5120x1440@120"
      "video=DP-3:3840x2160@60"
    ];


    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
      # verbose = false;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "rw" "noatime" "ssd" "subvol=/@" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
    };

    "/home/khaneliman/Downloads" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [ "rw" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@userdata/@downloads" ];
    };

    "/home/khaneliman/Documents" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [ "rw" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@userdata/@documents" ];
    };

    "/home/khaneliman/Pictures" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [ "rw" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@userdata/@pictures" ];
    };

    "/home/khaneliman/Videos" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [ "rw" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@userdata/@videos" ];
    };

    "/home/khaneliman/Music" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [ "rw" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@userdata/@music" ];
    };

    "/mnt/kvm" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [ "rw" "nodatacow" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@kvm" ];
    };

    "/mnt/games" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [ "rw" "nodatacow" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@games" ];
    };

    "/mnt/steam" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [ "rw" "nodatacow" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@steam" ];
    };

    # "/mnt/steam-extra" = {
    #   device = "/dev/disk/by-label/BtrProductive";
    #   fsType = "btrfs";
    #   options = ["rw" "nodatacow" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@steam-extra"];
    # };
    #
    # "/mnt/extra" = {
    #   device = "/dev/disk/by-label/BtrProductive";
    #   fsType = "btrfs";
    #   options = ["rw" "nodatacow" "noatime" "compress-force=zstd:1" "ssd" "subvol=/@extra"];
    # };

    "/mnt/austinserver/appdata" = {
      device = "austinserver.local:/mnt/user/appdata";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/austinserver/data" = {
      device = "austinserver.local:/mnt/user/data";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/austinserver/backup" = {
      device = "austinserver.local:/mnt/user/backup";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/austinserver/isos" = {
      device = "austinserver.local:/mnt/user/isos";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/dropbox" = {
      device = "austinserver.local:/mnt/disks/dropbox";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/disks/googledrive" = {
      device = "austinserver.local:/mnt/disks/googledrive";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/disks/onedrive" = {
      device = "austinserver.local:/mnt/disks/onedrive";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/be1e6602-df3a-4d27-9d46-c52586093cb8"; }
  ];

  hardware = {
    enableRedistributableFirmware = true;
  };

  services = {
    rpcbind.enable = true; # needed for NFS
  };
}
