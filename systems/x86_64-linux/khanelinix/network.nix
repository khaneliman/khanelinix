{ config, ... }:
{
  networking = {
    networkmanager = {
      ensureProfiles = {
        profiles = {
        };
      };
    };
  };

  systemd = {
    network.networks = {
      # wired interfaces e.g. ethernet
      "30-network-defaults-wired" = {
        matchConfig.Name = "en* | eth* | usb*";
        networkConfig = {
          Address = "192.168.1.3/24";
          Gateway = "192.168.1.1";
          # DHCP = "ipv4";
          # Enable if `mdns` is not handled by avahi
          MulticastDNS = !config.services.avahi.enable;
          # IPv6AcceptRA = true;
          # IPForward = "yes";
          # IPMasquerade = "no";
        };
      };
    };

    services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
  };
}
