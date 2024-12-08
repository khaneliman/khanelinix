{ lib, pkgs, ... }:
{
  specialisation = {
    zen = {
      inheritParentConfig = true;
      configuration = {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
      };
    };

    lts = {
      inheritParentConfig = true;
      configuration = {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
      };
    };
  };
}
