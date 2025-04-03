{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.system.networking;
in
{
  options.${namespace}.system.networking = {
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

    system.defaults = {
      # firewall settings
      alf = {
        # 0 = disabled 1 = enabled 2 = blocks all connections except for essential services
        globalstate = 1;
        loggingenabled = 0;
        stealthenabled = 0;
      };
    };
  };
}
