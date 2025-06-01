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

          support32Bit = {
            enable = true;
          };
          supportExperimental.enable = true;
        };
        initrd.enable = true;
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
    ];
  };
}
