{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.system.networking;
in
{
  options.khanelinix.system.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support";
    hosts =
      mkOpt attrs { }
        "An attribute set to merge with <option>networking.hosts</option>";
    nameServers = mkOpt (listOf str) [ "1.1.1.1" "8.8.8.8" ] "The nameservers to add.";
  };

  config = mkIf cfg.enable {
    khanelinix.user.extraGroups = [ "networkmanager" ];

    networking = {
      hosts =
        {
          "127.0.0.1" = [ "local.test" ] ++ (cfg.hosts."127.0.0.1" or [ ]);
        }
        // cfg.hosts;

      firewall = {
        trustedInterfaces = [ "tailscale0" ];
        # required to connect to Tailscale exit nodes
        checkReversePath = "loose";

        allowedUDPPorts = [
          # allow the Tailscale UDP port through the firewall
          config.services.tailscale.port
          5353
          # syncthing QUIC
          22000
          # syncthing discovery broadcast on ipv4 and multicast ipv6
          21027
        ];

        allowedTCPPorts = [
          42355
          # syncthing
          22000
        ];
      };

      nameservers = cfg.nameServers;

      networkmanager = {
        enable = true;

        connectionConfig = {
          "connection.mdns" = true;
        };
        dns = "systemd-resolved";
        dhcp = "internal";

        plugins = with pkgs; [
          networkmanager-l2tp
          networkmanager-openvpn
          networkmanager-sstp
          networkmanager-vpnc
        ];
      };
    };

    services.resolved.enable = true;

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  };
}
