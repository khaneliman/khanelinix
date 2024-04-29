{ lib, pkgs, ... }:
{
  specialisation = {
    # vfio = {
    #   inheritParentConfig = true;
    #
    #   configuration = {
    #     system.nixos.tags = [ "with-vfio" ];
    #     #   IOMMU Group 24:
    #     # 	05:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA102 [GeForce RTX 3080] [10de:2206] (rev a1)
    #     # 	05:00.1 Audio device [0403]: NVIDIA Corporation GA102 High Definition Audio Controller [10de:1aef] (rev a1)
    #     khanelinix.virtualisation.kvm = {
    #       enable = true;
    #       machineUnits = [ "machine-qemu\\x2d4\\x2dwin11\\x2dGPU.scope" ];
    #       platform = "amd";
    #       vfioIds = [ "10de:2206" "10de:1aef" ];
    #     };
    #   };
    # };

    zen = {
      inheritParentConfig = true;
      configuration = {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
      };
    };

    lts = {
      inheritParentConfig = true;
      configuration = {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
      };
    };

    nvidialess = {
      inheritParentConfig = true;

      configuration = {
        system.nixos.tags = [ "no-nvidia" ];

        boot.extraModprobeConfig = ''
          blacklist nouveau
          options nouveau modeset=0
        '';

        services.udev.extraRules = ''
          # Remove NVIDIA USB xHCI Host Controller devices, if present
          ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"

          # Remove NVIDIA USB Type-C UCSI devices, if present
          ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"

          # Remove NVIDIA Audio devices, if present
          ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"

          # Remove NVIDIA VGA/3D controller devices
          ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
        '';
        boot.blacklistedKernelModules = [
          "nouveau"
          "nvidia"
          "nvidia_drm"
          "nvidia_modeset"
        ];
      };
    };
  };
}
