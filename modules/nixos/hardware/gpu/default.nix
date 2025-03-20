{ lib, namespace, ... }:
{
  options.${namespace}.hardware.gpu = {
    enable = lib.mkEnableOption "No-op for setting up hierarchy";
  };
}
