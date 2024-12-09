{ pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
  };
}
