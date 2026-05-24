{ lib, ... }:
{
  khanelinix.system.networking.hosts = {
    "127.0.0.1" = [
      "AustinServer"
      "AustinServer.local"
      "austinserver"
      "austinserver.local"
      "khanelilab"
      "khanelilab.local"
    ];
    "192.168.4.20" = [
      "AustinServer"
      "AustinServer.local"
      "austinserver"
      "austinserver.local"
      "khanelilab"
      "khanelilab.local"
    ];
  };

  networking = {
    defaultGateway = {
      address = "192.168.4.1";
      interface = "br0";
    };

    bridges.br0.interfaces = [ "eth0" ];

    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.4.20";
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
}
