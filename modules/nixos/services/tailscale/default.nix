{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.modules) mkBefore;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.services.tailscale;
in
{
  options.${namespace}.services.tailscale = with types; {
    enable = mkBoolOpt false "Whether or not to configure Tailscale";
    autoconnect = {
      enable = mkBoolOpt false "Whether or not to enable automatic connection to Tailscale";
      key = mkOpt str "" "The authentication key to use";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.autoconnect.enable -> cfg.autoconnect.key != "";
        message = "${namespace}.services.tailscale.autoconnect.key must be set";
      }
    ];

    boot.kernel.sysctl = {
      # Enable IP forwarding
      # required for Wireguard & Tailscale/Headscale subnet feature
      # See <https://tailscale.com/kb/1019/subnets/?tab=linux#step-1-install-the-tailscale-client>
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    environment.systemPackages = with pkgs; [
      tailscale
      tailscale-systray
    ];

    networking = {
      firewall = {
        allowedUDPPorts = [ config.services.tailscale.port ];
        allowedTCPPorts = [ 5900 ];
        trustedInterfaces = [ config.services.tailscale.interfaceName ];
        # Strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups.
        checkReversePath = "loose";
      };

      networkmanager.unmanaged = [ "tailscale0" ];
    };

    services.tailscale = {
      enable = true;
      permitCertUid = "root";
      useRoutingFeatures = "both";
    };

    systemd = {
      network.wait-online.ignoredInterfaces = [ "${config.services.tailscale.interfaceName}" ];

      services = {
        tailscaled.serviceConfig.Environment = mkBefore [ "TS_NO_LOGS_NO_SUPPORT=true" ];

        tailscale-autoconnect = mkIf cfg.autoconnect.enable {
          description = "Automatic connection to Tailscale";

          # Make sure tailscale is running before trying to connect to tailscale
          after = [
            "network-pre.target"
            "tailscale.service"
          ];
          wants = [
            "network-pre.target"
            "tailscale.service"
          ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig.Type = "oneshot";

          script =
            with pkgs; # bash
            ''
              # Wait for tailscaled to settle
              sleep 2

              # Check if we are already authenticated to tailscale
              status="$(${getExe tailscale} status -json | ${getExe jq} -r .BackendState)"
              if [ $status = "Running" ]; then # if so, then do nothing
                exit 0
              fi

              # Otherwise authenticate with tailscale
              ${getExe tailscale} up -authkey "${cfg.autoconnect.key}"
            '';
        };
      };
    };
  };
}
