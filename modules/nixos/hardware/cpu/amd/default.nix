{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.hardware.cpu.amd;
in
{
  options.khanelinix.hardware.cpu.amd = {
    enable = mkBoolOpt false "Whether or not to enable support for amd cpu.";
  };

  config = mkIf cfg.enable {
    boot = {
      extraModulePackages = [ config.boot.kernelPackages.zenpower ];

      kernelModules = [
        "kvm-amd" # amd virtualization
        "amd-pstate" # load pstate module in case the device has a newer gpu
        "zenpower" # zenpower is for reading cpu info, i.e voltage
        "msr" # x86 CPU MSR access device
      ];

      kernelParams = [ "amd_pstate=active" ];
    };

    environment.systemPackages = [ pkgs.amdctl ];

    hardware.cpu.amd.updateMicrocode = true;
  };
}
