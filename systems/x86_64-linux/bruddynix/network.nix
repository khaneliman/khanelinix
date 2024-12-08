_: {
  systemd = {
    network.networks = {
      "30-network-defaults-wired" = {
        matchConfig.Name = "en* | eth* | usb*";
        networkConfig = {
          DHCP = "ipv4";
          MulticastDNS = true;
        };
      };
    };
  };
}
