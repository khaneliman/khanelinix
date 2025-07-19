{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.hardware.fingerprint;
in
{
  options.khanelinix.hardware.fingerprint = {
    enable = lib.mkEnableOption "fingerprint support";
  };

  config = mkIf cfg.enable { services.fprintd.enable = true; };
}
