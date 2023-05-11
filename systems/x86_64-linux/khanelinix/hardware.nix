{ config
, lib
, pkgs
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
    common-pc
    common-pc-ssd
  ];

  ##
  # Desktop VM config
  ##
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "video=DP-1:5120x1440@120"
      "video=DP-3:3840x2160@60"
      "quiet"
    ];

    initrd = {
      kernelModules = [ ];
      availableKernelModules = [ "nvme" "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
    };

    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "rw" "noatime" "ssd" "subvol=/@" ];
    };

    "/boot/efi" = {
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
      device = "192.168.1.37:/mnt/user/appdata";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/austinserver/data" = {
      device = "192.168.1.37:/mnt/user/data";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/austinserver/backup" = {
      device = "192.168.1.37:/mnt/user/backup";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/austinserver/isos" = {
      device = "192.168.1.37:/mnt/user/isos";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/dropbox" = {
      device = "192.168.1.37:/mnt/disks/dropbox";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/disks/googledrive" = {
      device = "192.168.1.37:/mnt/disks/googledrive";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };

    "/mnt/disks/onedrive" = {
      device = "192.168.1.37:/mnt/disks/onedrive";
      fsType = "nfs";
      options = [ "noauto" "x-systemd.automount" "x-systemd.requires=network.target" "x-systemd.mount-timeout=10" "x-systemd.idle-timeout=1min" ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/be1e6602-df3a-4d27-9d46-c52586093cb8"; }
  ];

  hardware = {
    bluetooth.enable = true;
    enableRedistributableFirmware = true;
  };

  services = {
    rpcbind.enable = true; # needed for NFS
  };
}
