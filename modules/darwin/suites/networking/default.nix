{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.networking;
in
{
  options.khanelinix.suites.networking = {
    enable = lib.mkEnableOption "networking configuration";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      services = {
        tailscale = lib.mkDefault enabled;
      };

      system = {
        networking = lib.mkDefault enabled;
      };
    };
  };
}
