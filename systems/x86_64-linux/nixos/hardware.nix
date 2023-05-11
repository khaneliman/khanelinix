{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}: let
  inherit (inputs) nixos-hardware;
in {
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  ##
  # Desktop VM config
  ##
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      kernelModules = [ "kvm-amd" ];
      availableKernelModules = ["nvme" "ahci" "xhci_pci" "virtio_pci" "virtio_blk" "sr_mod"];
    };

    extraModulePackages = [];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  swapDevices = [];

  hardware.enableRedistributableFirmware = true;

  # services.xserver.videoDrivers = [ "amdgpu" ];
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.bluetooth.enable = true;
}
