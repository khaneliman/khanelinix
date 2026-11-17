{ config, ... }:
{
  # T3 Code server LAN route; the home config enables its --lan listener.
  # Tailscale already trusts tailscale0, so only the wired LAN needs this.
  networking.firewall.interfaces.enp5s0.allowedTCPPorts = [ 3773 ];

  systemd = {
    network.networks = {
      # wired interfaces e.g. ethernet
      "30-network-defaults-wired" = {
        matchConfig.Name = "en* | eth* | usb*";
        DHCP = "ipv4";
        linkConfig = {
          # Link-level multicast must stay on for mDNS regardless of which
          # daemon handles it; avahi can't bind interfaces without IFF_MULTICAST.
          Multicast = true;
        };
        networkConfig = {
          # Enable if `mdns` is not handled by avahi
          MulticastDNS = if !config.services.avahi.enable then "yes" else "no";
          IPv6AcceptRA = true;
        };
      };
    };
  };
}
