{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.hardware.gpu.amd;
in
{
  options.${namespace}.hardware.gpu.amd = {
    enable = mkBoolOpt false "Whether or not to enable support for amdgpu.";
  };

  config = mkIf cfg.enable {
    # enable amdgpu kernel module
    boot = {
      initrd.kernelModules = [ "amdgpu" ]; # load amdgpu kernel module as early as initrd
      kernelModules = [ "amdgpu" ]; # if loading somehow fails during initrd but the boot continues, try again later
    };

    environment.systemPackages = with pkgs; [
      amdgpu_top
      nvtopPackages.amd
    ];

    environment.variables = {
      # VAAPI and VDPAU config for accelerated video.
      # See https://wiki.archlinux.org/index.php/Hardware_video_acceleration
      "VDPAU_DRIVER" = "radeonsi";
      "LIBVA_DRIVER_NAME" = "radeonsi";
    };

    # enables AMDVLK & OpenCL support
    hardware.graphics = {
      extraPackages =
        with pkgs;
        [
          amdvlk

          # mesa
          mesa

          # vulkan
          vulkan-tools
          vulkan-loader
          vulkan-validation-layers
          vulkan-extension-layer
        ]
        ++ (
          if pkgs ? rocmPackages.clr then
            with pkgs.rocmPackages;
            [
              clr
              clr.icd
            ]
          else
            with pkgs;
            [
              rocm-opencl-icd
              rocm-opencl-runtime
            ]
        );

      extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
    };

    services.xserver.videoDrivers = lib.mkDefault [
      "modesetting"
      "amdgpu"
    ];
  };
}
