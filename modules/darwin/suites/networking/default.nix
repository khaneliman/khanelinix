{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.networking;
in
{
  options.khanelinix.suites.networking = {
    enable = mkBoolOpt false "Whether or not to enable networking configuration.";
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
