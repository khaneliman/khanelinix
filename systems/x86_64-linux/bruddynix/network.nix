{ config, ... }:
{
  # FIXME: breaks internet access for some reason
  # networking = {
  #   nameservers = lib.mkForce [
  #     # Cloudflare for families
  #     "1.1.1.3"
  #     "1.0.0.3"
  #     "2606:4700:4700::1113"
  #     "2606:4700:4700::1003"
  #   ];
  # };

  systemd = {
    network.networks = {
      "30-network-defaults-wired" = {
        matchConfig.Name = "en* | eth* | usb*";
        networkConfig = {
          DHCP = "ipv4";
          # Enable if `mdns` is not handled by avahi
          MulticastDNS = !config.services.avahi.enable;
        };
      };
    };
  };
}
