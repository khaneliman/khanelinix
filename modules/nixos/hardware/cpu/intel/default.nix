{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.hardware.cpu.intel;
in
{
  options.khanelinix.hardware.cpu.intel = {
    enable = mkBoolOpt false "Whether or not to enable support for intel cpu.";
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
