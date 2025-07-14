{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.hardware.cpu.intel;
in
{
  options.khanelinix.hardware.cpu.intel = {
    enable = lib.mkEnableOption "support for intel cpu";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ intel-gpu-tools ];

    hardware.cpu.intel.updateMicrocode = true;

    boot = {
      kernelModules = [ "kvm-intel" ];

      kernelParams = [
        "i915.fastboot=1"
        "enable_gvt=1"
      ];
    };
  };
}
