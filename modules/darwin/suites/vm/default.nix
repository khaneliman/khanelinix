{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.vm;
in
{
  options.${namespace}.suites.vm = {
    enable = mkBoolOpt false "Whether or not to enable vm.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # FIX: broken nixpkg on darwin
      # qemu
      # FIX: broken nixpkg on darwin
      # vte
      # FIX: broken nixpkg on darwin
      # libvirt
    ];

    homebrew = {
      taps = [ "arthurk/virt-manager" ];

      casks = [ "utm" ];
    };
  };
}
