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

    # enables AMDVLK & OpenCL support
    hardware = {
      amdgpu = {
        initrd.enable = true;
        opencl.enable = true;
        overdrive = {
          enable = true;
          # Full feature mask for all power management features
          # Default 0xfffd7fff is conservative; 0xffffffff enables all (may cause flicker on some cards)
          ppfeaturemask = "0xffffffff";
        };
      };

      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          vulkan-tools
        ];
      };
    };

    nixpkgs.config.rocmSupport = cfg.enableRocmSupport;

    # Allow userspace tools (like gamemode) to control GPU performance
    services.udev.extraRules = ''
      KERNEL=="card[0-9]", SUBSYSTEM=="drm", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/drm/%k/device/power_dpm_force_performance_level"
    '';
  };
}
