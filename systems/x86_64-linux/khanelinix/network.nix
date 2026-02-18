{ config, ... }:
{
  systemd = {
    network.networks = {
      # wired interfaces e.g. ethernet
      "30-network-defaults-wired" = {
        matchConfig.Name = "en* | eth* | usb*";
        linkConfig = {
          Multicast = if !config.services.avahi.enable then "yes" else "no";
        };
        networkConfig = {
          DHCP = "ipv4";
          # Enable if `mdns` is not handled by avahi
          MulticastDNS = if !config.services.avahi.enable then "yes" else "no";
          IPMasquerade = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };
  };
}
