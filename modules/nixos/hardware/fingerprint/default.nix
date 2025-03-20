{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.hardware.fingerprint;
in
{
  options.${namespace}.hardware.fingerprint = {
    enable = lib.mkEnableOption "fingerprint support";
  };

  config = mkIf cfg.enable { services.fprintd.enable = true; };
}
