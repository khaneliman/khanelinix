{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.emulationstation;
in
{
  options.khanelinix.apps.emulationstation = with types; {
    enable = mkBoolOpt false "Whether or not to enable emulationstation.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      emulationstation
    ];
  };
}
