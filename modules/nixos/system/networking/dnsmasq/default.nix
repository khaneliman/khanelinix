{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkForce;

  cfg = config.${namespace}.system.networking;
in
{
  config = mkIf (cfg.dns == "dnsmasq") {
    networking.networkmanager.dns = "dnsmasq";
    services.resolved.enable = mkForce false;
    services.dnsmasq = {
      enable = true;

      resolveLocalQueries = true;

      settings = {
        server = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
      };
    };

  };
}
