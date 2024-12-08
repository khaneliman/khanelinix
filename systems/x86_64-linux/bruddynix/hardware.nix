{ pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  ##
  # Desktop VM config
  ##
  boot = {
    blacklistedKernelModules = [ "eeepc_wmi" ];

    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl."kernel.sysrq" = 1;

    initrd = {
      availableKernelModules = [
        "ahci"
        # "ehci_pci"
        "nvme"
        "sd_mod"
        # "sr_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
      # verbose = false;
    };
  };

  # fileSystems = {
  #   "/" = {
  #     device = "/dev/disk/by-label/nixos";
  #     fsType = "ext4";
  #   };
  #
  #   "/boot" = {
  #     device = "/dev/disk/by-label/ESP";
  #     fsType = "vfat";
  #     options = [
  #       "fmask=0077"
  #       "dmask=0077"
  #     ];
  #   };
  # };

  # swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  hardware = {
    enableRedistributableFirmware = true;
  };
}
