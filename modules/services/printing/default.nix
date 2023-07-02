{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.services.printing;
in {
  options.khanelinix.services.printing = with types; {
    enable = mkBoolOpt false "Whether or not to configure printing support.";
  };

  config = mkIf cfg.enable {
    services.printing.enable = true;

    services.printing.drivers = with pkgs; [
      brlaser
    ];
  };
}
