{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkForce;

  cfg = config.${namespace}.system.networking;
in
{
  config = mkIf (cfg.enable && cfg.manager == "systemd-networkd") {
    networking.useNetworkd = mkForce true;

    services.networkd-dispatcher.enable = true;

    # https://wiki.nixos.org/wiki/Systemd-networkd
    systemd.network = {
      enable = true;

      wait-online = {
        enable = true;
        anyInterface = true;
        extraArgs = [ "--ipv4" ];
      };

      # https://wiki.archlinux.org/title/Systemd-networkd
      networks = {
        # leave the kernel dummy devices unmanagaed
        "10-dummy" = {
          matchConfig.Name = "dummy*";
          networkConfig = { };
          # linkConfig.ActivationPolicy = "always-down";
          linkConfig.Unmanaged = "yes";
        };

        # let me configure tailscale manually
        "20-tailscale-ignore" = mkIf config.${namespace}.services.tailscale.enable {
          matchConfig.Name = "tailscale*";
          linkConfig = {
            Unmanaged = "yes";
            RequiredForOnline = false;
          };
        };
      };
    };
  };
}
