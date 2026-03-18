{ lib, pkgs, ... }:
{
  specialisation = {
    safe = {
      inheritParentConfig = true;
      configuration = {
        boot = {
          # Use the regular kernel stack instead of zen for a conservative fallback.
          kernelPackages = lib.mkForce pkgs.linuxPackages;
          # Avoid TPM setup paths in the fallback profile since they are failing
          # early in boot on this host and add no recovery value.
          initrd.systemd.tpm2.enable = lib.mkForce false;
          # Keep display-control helper modules out of the recovery profile.
          blacklistedKernelModules = lib.mkAfter [
            "ddcci"
            "ddcci_backlight"
          ];
        };

        # Keep the safe profile on a plain TTY so recovery is possible even if
        # the graphical stack is unstable.
        systemd.defaultUnit = lib.mkForce "multi-user.target";

        khanelinix = {
          display-managers.sddm.enable = lib.mkForce false;
          hardware.tpm.enable = lib.mkForce false;
          # Keep boot verbose so failures are visible instead of hidden behind splash/quiet.
          system.boot.plymouth = lib.mkForce false;
          system.boot.silentBoot = lib.mkForce false;
          services.ddccontrol.enable = lib.mkForce false;
          services.lact.enable = lib.mkForce false;
        };

        # Disable userspace/kernel tuning knobs that can push unstable clocks.
        hardware = {
          amdgpu.initrd.enable = lib.mkForce false;
          display.outputs = lib.mkForce { };
          amdgpu.overdrive.enable = lib.mkForce false;
          cpu.amd.ryzen-smu.enable = lib.mkForce false;
        };
      };
    };
  };
}
