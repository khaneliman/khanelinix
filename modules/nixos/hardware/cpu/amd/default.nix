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
    # Ryzen SMU: Low-level access to System Management Unit for monitoring/tuning
    hardware.cpu.amd.ryzen-smu.enable = true;

    boot = {
      blacklistedKernelModules = [ "k10temp" ];
      extraModulePackages = [ config.boot.kernelPackages.zenpower ];
      kernelModules = [
        "kvm-amd" # amd virtualization
        "zenpower" # zenpower is for reading cpu info, i.e voltage
        "msr" # x86 CPU MSR access device
      ];

      # The amd-pstate driver offers several operational modes that dictate the level of control shared between the operating system and the CPU firmware.
      # https://docs.kernel.org/admin-guide/pm/amd-pstate.html#amd-pstate-driver-operation-modes
      # passive: In this mode, the driver behaves similarly to the legacy acpi-cpufreq driver, with the OS requesting specific performance states (P-states). It does not fully leverage the CPPC mechanism and is generally not the recommended choice.
      # active (EPP): In this mode, also known as Energy Performance Preference (EPP), the driver provides a simple "hint" to the CPU firmware, biasing it towards either performance or energy efficiency. The firmware then autonomously makes the final, granular frequency decisions based on real-time workload, thermal, and power conditions.
      # guided: This mode represents a hybrid approach. The OS governor requests a minimum and maximum performance level, and the hardware platform is then free to autonomously select the most appropriate frequency within that range.
      kernelParams = [
        "amd_pstate=active"

        # Potential stability fixes
        "amdgpu.sg_display=0"
        "amdgpu.dcdebugmask=0x10"
      ];
    };

    environment.systemPackages = [ pkgs.amdctl ];

    hardware.cpu.amd.updateMicrocode = true;

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };
  };
}
