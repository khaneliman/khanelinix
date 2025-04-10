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
  config = mkIf (cfg.enable && cfg.manager == "networkmanager") {
    khanelinix.user.extraGroups = [ "networkmanager" ];

    networking = {
      networkmanager = {
        enable = true;

        connectionConfig = {
          # Enable if `mdns` is not handled by avahi
          "connection.mdns" = lib.mkIf (!config.services.avahi.enable) "2";
        };

        plugins = with pkgs; [
          networkmanager-l2tp
          networkmanager-openvpn
          networkmanager-sstp
          networkmanager-vpnc
        ];

        unmanaged =
          [
            "interface-name:br-*"
            "interface-name:rndis*"
          ]
          ++ lib.optionals config.${namespace}.services.tailscale.enable [ "interface-name:tailscale*" ]
          ++ lib.optionals config.${namespace}.virtualisation.podman.enable [ "interface-name:docker*" ]
          ++ lib.optionals config.${namespace}.virtualisation.kvm.enable [ "interface-name:virbr*" ];
      };

      resolvconf.enable = false;
    };
  };
}
