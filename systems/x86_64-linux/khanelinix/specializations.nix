{
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  safeBtrfsOptions = [
    "defaults"
    "compress=zstd:1"
    "ssd"
    "noatime"
    "nodiratime"
  ];
in
{
  specialisation = {
    safe = {
      inheritParentConfig = false;
      configuration = {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
          ../../../modules/nixos/user
          ../../../modules/nixos/services/openssh
        ];

        system.stateVersion = "26.05";

        boot = {
          # Use the regular kernel stack instead of zen for a conservative fallback.
          kernelPackages = lib.mkForce pkgs.linuxPackages;
          kernelParams = [
            "iommu=pt"
            "pcie_aspm=off"
          ];
          kernel.sysctl."kernel.sysrq" = 1;

          # Avoid TPM setup paths in the fallback profile since they are failing
          # early in boot on this host and add no recovery value.
          initrd.systemd.tpm2.enable = lib.mkForce false;
          initrd.availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ehci_pci"
            "ahci"
            "usb_storage"
            "usbhid"
            "sd_mod"
            "sr_mod"
          ];

          # Keep display-control helper modules out of the recovery profile.
          blacklistedKernelModules = lib.mkAfter [
            "eeepc_wmi"
            "ccp"
            "ddcci"
            "ddcci_backlight"
          ];
        };

        # Keep the safe profile on a plain TTY so recovery is possible even if
        # the graphical stack is unstable.
        systemd.defaultUnit = lib.mkForce "multi-user.target";

        fileSystems = {
          "/" = {
            device = "/dev/disk/by-partlabel/disk-nvme1-nixos";
            fsType = "btrfs";
            options = [
              "x-initrd.mount"
              "subvol=@"
            ]
            ++ safeBtrfsOptions;
          };

          "/boot" = {
            device = "/dev/disk/by-partlabel/disk-nvme0-efi";
            fsType = "vfat";
            options = [ "umask=0077" ];
          };
        };

        swapDevices = [
          {
            device = "/dev/disk/by-partlabel/disk-nvme0-swap";
            randomEncryption.enable = true;
          }
        ];

        networking = {
          hostName = "khanelinix-safe";
          useNetworkd = true;
        };

        systemd.network.networks."30-network-defaults-wired" = {
          matchConfig.Name = "en* | eth* | usb*";
          DHCP = "ipv4";
          linkConfig.Multicast = true;
          networkConfig.IPv6AcceptRA = true;
        };

        programs.zsh.enable = true;

        khanelinix = {
          services.openssh.enable = true;
        };

        environment.systemPackages = with pkgs; [
          git
          ripgrep
          vim
        ];

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    };
  };
}
