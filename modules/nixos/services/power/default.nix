{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.services.power;
in
{
  options.${namespace}.services.power = {
    enable = lib.mkEnableOption "power profiles";
  };

  config = mkIf cfg.enable { services.power-profiles-daemon.enable = cfg.enable; };
}
