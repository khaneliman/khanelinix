{ config, ... }:
{
  systemd = {
    network.networks = {
      # wired interfaces e.g. ethernet
      "30-network-defaults-wired" = {
        matchConfig.Name = "en* | eth* | usb*";
        linkConfig = {
          # Link-level multicast must stay on for mDNS regardless of which
          # daemon handles it; avahi can't bind interfaces without IFF_MULTICAST.
          Multicast = true;
        };
        networkConfig = {
          DHCP = "ipv4";
          # Enable if `mdns` is not handled by avahi
          MulticastDNS = if !config.services.avahi.enable then "yes" else "no";
          IPv6AcceptRA = true;
        };
      };
    };
  };
}
