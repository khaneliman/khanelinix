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
    common-cpu-intel
    common-pc
    common-pc-ssd
  ];

  boot = {
    blacklistedKernelModules = [
      "eeepc_wmi"
    ];

    kernel.sysctl."kernel.sysrq" = 1;

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
  };

  hardware = {
    enableRedistributableFirmware = true;
  };
}
