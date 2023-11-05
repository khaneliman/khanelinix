{ inputs
, ...
}:
let
  inherit (inputs) nixos-hardware;
in
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

    nvidialess = {
      inheritParentConfig = true;

      configuration = {
        system.nixos.tags = [ "no-nvidia" ];

        imports = with nixos-hardware.nixosModules; [
          common-gpu-nvidia-disable
        ];
      };
    };
  };
}
