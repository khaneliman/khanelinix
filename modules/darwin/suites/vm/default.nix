{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.vm;
in
{
  options.khanelinix.suites.vm = {
    enable = lib.mkEnableOption "vm";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      utm
      qemu
      vte
      libvirt
    ];
  };
}
