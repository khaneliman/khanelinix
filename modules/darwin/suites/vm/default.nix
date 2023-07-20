{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.vm;
in {
  options.khanelinix.suites.vm = with types; {
    enable = mkBoolOpt false "Whether or not to enable vm.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;

      global = {
        brewfile = true;
      };

      taps = [
        "arthurk/virt-manager"
      ];

      casks = [
        "utm"
      ];
    };
  };
}
