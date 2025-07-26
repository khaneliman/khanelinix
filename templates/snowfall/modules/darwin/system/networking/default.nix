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
      applicationFirewall = {
        enable = true;

        allowSignedApp = true;
        blockAllIncoming = false;
        enableStealthMode = false;
      };

      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };
}
