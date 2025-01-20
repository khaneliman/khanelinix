{ pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  ##
  # Desktop VM config
  ##
  boot = {
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "riscv64-linux"
    ];

    blacklistedKernelModules = [ "eeepc_wmi" ];

    # consoleLogLevel = 0;

    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl."kernel.sysrq" = 1;

    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
        "sr_mod"
      ];
      # verbose = false;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "ssd"
        "subvol=/@"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
      options = [
        "fmask=0137"
        "dmask=0027"
      ];
    };

    "/home/khaneliman/Downloads" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress-force=zstd:1"
        "ssd"
        "subvol=/@userdata/@downloads"
      ];
    };

    "/home/khaneliman/Documents" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress-force=zstd:1"
        "ssd"
        "subvol=/@userdata/@documents"
      ];
    };

    "/home/khaneliman/Pictures" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress-force=zstd:1"
        "ssd"
        "subvol=/@userdata/@pictures"
      ];
    };

    "/home/khaneliman/Videos" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress-force=zstd:1"
        "ssd"
        "subvol=/@userdata/@videos"
      ];
    };

    "/home/khaneliman/Music" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress-force=zstd:1"
        "ssd"
        "subvol=/@userdata/@music"
      ];
    };

    "/mnt/kvm" = {
      device = "/dev/disk/by-label/Linux";
      fsType = "btrfs";
      options = [
        "rw"
        "nodatacow"
        "noatime"
        "compress-force=zstd:1"
        "ssd"
        "subvol=/@kvm"
      ];
    };

    "/mnt/games" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [
        "rw"
        "nodatacow"
        "noatime"
        "compress-force=zstd:1"
        "ssd"
        "subvol=/@games"
      ];
    };

    "/mnt/steam" = {
      device = "/dev/disk/by-label/BtrProductive";
      fsType = "btrfs";
      options = [
        "rw"
        "nodatacow"
        "noatime"
        "compress-force=zstd:1"
        "ssd"
        "subvol=/@steam"
      ];
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
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.requires=network.target"
        "x-systemd.mount-timeout=10"
        "x-systemd.idle-timeout=1min"
      ];
    };

    "/mnt/austinserver/data" = {
      device = "austinserver.local:/mnt/user/data";
      fsType = "nfs";
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.requires=network.target"
        "x-systemd.mount-timeout=10"
        "x-systemd.idle-timeout=1min"
      ];
    };

    "/mnt/austinserver/backup" = {
      device = "austinserver.local:/mnt/user/backup";
      fsType = "nfs";
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.requires=network.target"
        "x-systemd.mount-timeout=10"
        "x-systemd.idle-timeout=1min"
      ];
    };

    "/mnt/austinserver/isos" = {
      device = "austinserver.local:/mnt/user/isos";
      fsType = "nfs";
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.requires=network.target"
        "x-systemd.mount-timeout=10"
        "x-systemd.idle-timeout=1min"
      ];
    };

    "/mnt/dropbox" = {
      device = "austinserver.local:/mnt/disks/dropbox";
      fsType = "nfs";
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.requires=network.target"
        "x-systemd.mount-timeout=10"
        "x-systemd.idle-timeout=1min"
      ];
    };

    "/mnt/disks/googledrive" = {
      device = "austinserver.local:/mnt/disks/googledrive";
      fsType = "nfs";
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.requires=network.target"
        "x-systemd.mount-timeout=10"
        "x-systemd.idle-timeout=1min"
      ];
    };

    "/mnt/disks/onedrive" = {
      device = "austinserver.local:/mnt/disks/onedrive";
      fsType = "nfs";
      options = [
        "noauto"
        "x-systemd.automount"
        "x-systemd.requires=network.target"
        "x-systemd.mount-timeout=10"
        "x-systemd.idle-timeout=1min"
      ];
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/be1e6602-df3a-4d27-9d46-c52586093cb8"; } ];

  hardware = {
    display = {
      outputs = {
        "DP-1" = {
          mode = "5120x1440@120";
        };
        "DP-3" = {
          mode = "3840x2160@60";
        };
      };
    };
    enableRedistributableFirmware = true;
  };
}
