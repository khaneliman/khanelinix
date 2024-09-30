{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.services.seatd;
in
{
  options.${namespace}.services.seatd = {
    enable = mkEnableOption "seatd";
  };

  config = mkIf cfg.enable {
    services = {
      seatd = {
        enable = true;
        # NOTE: does it matter?
        user = config.khanelinix.user.name;
      };
    };
  };
}
