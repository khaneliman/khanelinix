{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.hardware.fingerprint;
in
{
  options.khanelinix.hardware.fingerprint = {
    enable = mkBoolOpt false "Whether or not to enable fingerprint support.";
  };

  config = mkIf cfg.enable {
    services.fprintd.enable = true;
  };
}
