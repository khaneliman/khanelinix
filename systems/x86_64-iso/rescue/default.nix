{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];
  isoImage = {
    edition = "rescue";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };
  networking = {
    networkmanager.enable = lib.mkForce false;
    wireless.enable = lib.mkForce false;
    wireless.iwd.enable = lib.mkForce false;
    useDHCP = lib.mkForce false;
    useNetworkd = lib.mkForce false;
  };
  services = {
    openssh.enable = lib.mkForce false;
    resolved.enable = lib.mkForce false;
    timesyncd.enable = lib.mkForce false;
  };
  nix = {
    distributedBuilds = false;
    buildMachines = [ ];
    settings.substituters = lib.mkForce [ ];
  };
  environment.systemPackages = [
    pkgs.file
    pkgs.tmux
  ];
  system.stateVersion = "21.11";
}
