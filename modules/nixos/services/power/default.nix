{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.power;
in
{
  options.${namespace}.services.power = {
    enable = mkBoolOpt false "Whether or not to configure power profiles";
  };

  config = mkIf cfg.enable { services.power-profiles-daemon.enable = cfg.enable; };
}
