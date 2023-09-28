{ config
, lib
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.apps.caprine;
in
{
  options.khanelinix.apps.caprine = {
    enable = mkEnableOption "caprine";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "Caprine/custom.css".source = ./custom.css;
    };
  };
}
