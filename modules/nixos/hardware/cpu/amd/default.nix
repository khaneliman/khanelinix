{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.hardware.cpu.amd;
in
{
  options.khanelinix.hardware.cpu.amd = {
    enable = lib.mkEnableOption "support for amd cpu";
  };

  config = mkIf cfg.enable {
    boot = {
      blacklistedKernelModules = [ "k10temp" ];
      extraModulePackages = [ config.boot.kernelPackages.zenpower ];
      kernelModules = [
        "kvm-amd" # amd virtualization
        "zenpower" # zenpower is for reading cpu info, i.e voltage
        "msr" # x86 CPU MSR access device
      ];

      kernelParams = [ "amd_pstate=active" ];
    };

    environment.systemPackages = [ pkgs.amdctl ];

    hardware.cpu.amd.updateMicrocode = true;
  };
}
