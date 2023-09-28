{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.vm;
in
{
  options.khanelinix.suites.vm = {
    enable = mkBoolOpt false "Whether or not to enable vm.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      qemu
      vte
      libvirt
    ];

    homebrew = {
      taps = [
        "arthurk/virt-manager"
      ];

      casks = [
        "utm"
      ];
    };
  };
}
