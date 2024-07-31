{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.system.networking;
in
{
  config = mkIf cfg.enable {
    khanelinix.user.extraGroups = [ "networkmanager" ];

    networking.networkmanager = {
      enable = true;

      connectionConfig = {
        "connection.mdns" = "2";
      };

      plugins = with pkgs; [
        networkmanager-l2tp
        networkmanager-openvpn
        networkmanager-sstp
        networkmanager-vpnc
      ];

      unmanaged = [
        "interface-name:tailscale*"
        "interface-name:br-*"
        "interface-name:rndis*"
        "interface-name:docker*"
        "interface-name:virbr*"
      ];
    };

    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  };
}
