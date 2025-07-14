{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf mkForce;

  cfg = config.khanelinix.system.networking;
in
{
  config = mkIf (cfg.enable && cfg.dns == "systemd-resolved") {
    networking = {
      networkmanager.dns = "systemd-resolved";
      resolvconf.enable = false;
    };

    services.dnsmasq.enable = mkForce false;
    services.resolved = {
      enable = true;

      # dnssec = "true";
      # this is necessary to get tailscale picking up your headscale instance
      # and allows you to ping connected hosts by hostname
      domains = [ "~." ];
      dnsovertls = "true";

      extraConfig = lib.mkIf config.services.avahi.enable ''
        MulticastDNS=no
      '';

      fallbackDns = [
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
  };
}
