{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.hardware.gpu.amd;
in
{
  options.${namespace}.hardware.gpu.amd = {
    enable = lib.mkEnableOption "support for amdgpu";
    enableRocmSupport = lib.mkEnableOption "support for rocm";
    enableNvtop = lib.mkEnableOption "install nvtop for amd";
  };

  config = mkIf cfg.enable {
    # enable amdgpu kernel module
    boot = {
      initrd.kernelModules = [ "amdgpu" ]; # load amdgpu kernel module as early as initrd
      kernelModules = [ "amdgpu" ]; # if loading somehow fails during initrd but the boot continues, try again later
    };

    environment.systemPackages =
      with pkgs;
      [
        amdgpu_top
      ]
      ++ lib.optionals cfg.enableNvtop [
        nvtopPackages.amd
      ];

    environment.variables = {
      # VAAPI and VDPAU config for accelerated video.
      # See https://wiki.archlinux.org/index.php/Hardware_video_acceleration
      "VDPAU_DRIVER" = "radeonsi";
      "LIBVA_DRIVER_NAME" = "radeonsi";
    };

    # enables AMDVLK & OpenCL support
    hardware = {
      amdgpu = {
        amdvlk = {
          enable = true;
          package = pkgs.amdvlk;

          support32Bit = {
            enable = true;
          };
        };
        opencl.enable = true;
      };

      graphics = {
        extraPackages = with pkgs; [
          # mesa
          mesa

          # vulkan
          vulkan-tools
          vulkan-loader
          vulkan-validation-layers
          vulkan-extension-layer
        ];
      };
    };

    nixpkgs.config.rocmSupport = cfg.enableRocmSupport;

    services.xserver.videoDrivers = lib.mkDefault [
      "modesetting"
      "amdgpu"
    ];
  };
}
