{
  lib,
  config,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.power;
in
{
  options.khanelinix.services.power = {
    enable = lib.mkEnableOption "power profiles";
  };

  config = mkIf cfg.enable { services.power-profiles-daemon.enable = cfg.enable; };
}
