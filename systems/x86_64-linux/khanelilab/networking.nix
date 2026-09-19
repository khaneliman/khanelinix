{ config, lib, ... }:
let
  hostAddress = config.khanelinix.system.networking.hostAddress;
in
{
  khanelinix.system.networking = {
    hostAddress = "192.168.4.42";

    hosts = {
      "127.0.0.1" = [
        "AustinServer"
        "AustinServer.local"
        "austinserver"
        "austinserver.local"
        "khanelilab"
        "khanelilab.local"
      ];
      ${hostAddress} = [
        "AustinServer"
        "AustinServer.local"
        "austinserver"
        "austinserver.local"
        "khanelilab"
        "khanelilab.local"
      ];
    };
  };

  networking = {
    defaultGateway = {
      address = "192.168.4.1";
      interface = "br0";
    };

    bonds.bond0 = {
      driverOptions = {
        miimon = "100";
        mode = "active-backup";
        primary = "lan0";
      };
      interfaces = [
        "lan0"
      ];
    };

    bridges.br0.interfaces = [ "bond0" ];

    interfaces.br0.ipv4.addresses = [
      {
        address = hostAddress;
        prefixLength = 22;
      }
    ];

    firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      checkReversePath = lib.mkForce "loose";
      trustedInterfaces = [ "br0" ];
    };
  };

  systemd.network.links."10-lab-lan" = {
    matchConfig.PermanentMACAddress = "d8:bb:c1:1c:35:18";
    linkConfig.Name = "lan0";
  };
}
