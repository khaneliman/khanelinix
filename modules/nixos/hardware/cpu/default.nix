{ lib, namespace, ... }:
{
  options.${namespace}.hardware.cpu = {
    enable = lib.mkEnableOption "No-op used for setting up hierarchy";
  };
}
