{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.hardware.gpu.amd;
in
{
  options.khanelinix.hardware.gpu.amd = {
    enable = lib.mkEnableOption "support for amdgpu";
    enableRocmSupport = lib.mkEnableOption "support for rocm";
    enableNvtop = lib.mkEnableOption "install nvtop for amd";
    rocmGfxVersion = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "11.0.0";
      description = "HSA_OVERRIDE_GFX_VERSION / rocmOverrideGfx value for ROCm services.";
    };
    rocmGfxTarget = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "gfx1100";
      description = "AMDGPU GFX architecture target (for example gfx1100) for ROCm services.";
    };
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

    hardware = {
      amdgpu = {
        initrd.enable = true;
        opencl.enable = true;
      };

      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          vulkan-tools
        ];
      };
    };

    nixpkgs.config.rocmSupport = cfg.enableRocmSupport;

  };
}
