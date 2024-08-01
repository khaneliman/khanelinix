_: {
  networking = {
    networkmanager = {
      ensureProfiles = {
        profiles = {
          dib = {
            connection = {
              id = "DiB";
              type = "vpn";
              autoconnect = false;

              # permissions = "match-domain:domain=*.doitbestcorp.com,interface-name=tun0;";
            };

            vpn = {
              authtype = "password";
              autoconnect-flags = 0;
              certsigs-flags = 0;
              cookie-flags = 2;
              disable_udp = "no";
              enable_csd_trojan = "no";
              gateway = "https://vendoraccess.doitbestcorp.com/";
              gateway-flags = 2;
              gwcert-flags = 2;
              lasthost-flags = 0;
              pem_passphrase_fsid = "no";
              prevent_invalid_cert = "no";
              protocol = "gp";
              resolve-flags = 2;
              stoken_source = "disabled";
              xmlconfig-flags = 0;
              service-type = "org.freedesktop.NetworkManager.openconnect";
            };

            ipv4 = {
              dns-search = "~doitbestcorp.com";
              method = "auto";
            };

            ipv6 = {
              addr-gen-mode = "stable-privacy";
              method = "auto";
            };
          };
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
          # Address = "192.168.1.3/24";
          # Gateway = "192.168.1.1";
          DHCP = "ipv4";
          MulticastDNS = true;
          # IPv6AcceptRA = true;
          # IPForward = "yes";
          # IPMasquerade = "no";
        };
      };
    };

    services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";
  };
}
