{
  config,
  lib,
  hostname,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.system.hostname;
in
{
  options.khanelinix.system.hostname = {
    enable = mkBoolOpt true "Whether to configure the system hostname.";
  };

  config = mkIf cfg.enable {
    networking.hostName = hostname;
  };
}
