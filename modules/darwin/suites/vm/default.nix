{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.suites.vm;
in
{
  options.khanelinix.suites.vm = {
    enable = mkBoolOpt false "Whether or not to enable vm.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # FIX: broken nixpkg on darwin
      # qemu
      vte
      # FIX: broken nixpkg on darwin
      # libvirt
    ];

    homebrew = {
      taps = [ "arthurk/virt-manager" ];

      casks = [ "utm" ];
    };
  };
}
