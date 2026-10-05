{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];
  isoImage = {
    edition = "minimal";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };
  system.stateVersion = "26.11";
}
