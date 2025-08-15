{
  lib,
  pkgs,
  modulesPath,

  ...
}:
let
  inherit (lib.khanelinix) enabled;
in
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

    blacklistedKernelModules = [
      "eeepc_wmi"
    ];

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

  fileSystems =
    lib.mapAttrs'
      (mountPoint: serverPath: {
        name = mountPoint;
        value = {
          device = "austinserver.local:${serverPath}";
          fsType = "nfs";
          options = [
            "noauto" # Don't mount at boot.
            "x-systemd.automount" # Mount on first access.
            "x-systemd.mount-timeout=10s" # Timeout for the mount operation.
            "x-systemd.idle-timeout=1min" # Unmount after 1 minute of inactivity.
            "x-systemd.requires=network-online.target" # Wait for an active connection.
            "soft" # Prevent hangs if the server goes down.
          ];
        };
      })
      {
        "/mnt/austinserver/appdata" = "/mnt/user/appdata";
        "/mnt/austinserver/data" = "/mnt/user/data";
        "/mnt/austinserver/backup" = "/mnt/user/backup";
        "/mnt/austinserver/isos" = "/mnt/user/isos";
        "/mnt/dropbox" = "/mnt/disks/dropbox";
        "/mnt/disks/googledrive" = "/mnt/disks/googledrive";
        "/mnt/disks/onedrive" = "/mnt/disks/onedrive";
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

  khanelinix = {
    hardware = {
      audio = {
        enable = true;
      };
      bluetooth = enabled;
      cpu.amd = enabled;
      gpu = {
        amd = {
          enable = true;
          enableRocmSupport = true;
          enableNvtop = true;
        };
      };
      opengl = enabled;

      rgb = {
        openrgb.enable = true;
      };

      storage = {
        enable = true;

        btrfs = {
          enable = true;
          autoScrub = true;
          # dedupe = true;

          dedupeFilesystems = [
            "nixos"
            "BtrProductive"
          ];

          scrubMounts = [
            "/"
            "/mnt/steam"
          ];
        };

        ssdEnable = true;
      };

      tpm = enabled;
      yubikey = enabled;
    };
  };

  # Tune CPU with nix
  # Currently 5950x
  nix.settings = {
    cores = 16;
    max-jobs = 8;
  };

}
