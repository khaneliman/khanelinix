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
        };

        khanelinix = {
          hardware.tpm.enable = lib.mkForce false;
          # Keep boot verbose so failures are visible instead of hidden behind splash/quiet.
          system.boot.plymouth = lib.mkForce false;
          system.boot.silentBoot = lib.mkForce false;
          services.lact.enable = lib.mkForce false;
        };

        # Disable userspace/kernel tuning knobs that can push unstable clocks.
        hardware = {
          amdgpu.overdrive.enable = lib.mkForce false;
          cpu.amd.ryzen-smu.enable = lib.mkForce false;
        };
      };
    };
  };
}
