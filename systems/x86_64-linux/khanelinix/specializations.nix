{ lib, pkgs, ... }:
{
  specialisation = {
    safe = {
      inheritParentConfig = true;
      configuration = {
        # Use the regular kernel stack instead of zen for a conservative fallback.
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

        # Disable userspace/kernel tuning knobs that can push unstable clocks.
        hardware.amdgpu.overdrive.enable = lib.mkForce false;
        khanelinix.services.lact.enable = lib.mkForce false;
        services.lact.enable = lib.mkForce false;
        hardware.cpu.amd.ryzen-smu.enable = lib.mkForce false;
      };
    };
  };
}
