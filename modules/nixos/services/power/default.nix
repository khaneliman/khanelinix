{
  lib,
  config,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.services.power;
in
{
  options.khanelinix.services.power = {
    enable = mkBoolOpt false "Whether or not to configure power profiles";
  };

  config = mkIf cfg.enable { services.power-profiles-daemon.enable = cfg.enable; };
}
