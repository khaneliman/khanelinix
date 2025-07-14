{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.system.networking;
in
{
  options.khanelinix.system.networking = {
    enable = lib.mkEnableOption "networking support";
  };

  config = mkIf cfg.enable {
    networking = {
      dns = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
    };
  };
}
