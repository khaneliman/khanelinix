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
