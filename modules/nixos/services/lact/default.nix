{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.lact;
in
{
  options.khanelinix.services.lact = {
    enable = lib.mkEnableOption "lact";
  };

  config = mkIf cfg.enable {
    services.lact.enable = true;
  };
}
