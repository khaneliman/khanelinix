{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.emulationstation;
in
{
  options.khanelinix.apps.emulationstation = {
    enable = mkBoolOpt false "Whether or not to enable emulationstation.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      emulationstation
    ];
  };
}
