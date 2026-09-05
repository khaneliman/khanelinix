{
  lib,
  pkgs,
  config,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.services.tailscale;
in
{
  options.khanelinix.services.tailscale = with types; {
    enable = lib.mkEnableOption "Tailscale";
    autoconnect = {
      enable = lib.mkEnableOption "automatic connection to Tailscale";
      keyFile =
        mkOpt (nullOr path) null
          "File holding the auth key, read at runtime so it stays out of the store.";
    };
    acceptRoutes = lib.mkEnableOption "routes advertised by other Tailscale nodes";
    advertiseExitNode = lib.mkEnableOption "this host as a Tailscale exit node";
    advertiseRoutes = mkOpt (listOf str) [ ] "Subnet routes to advertise through Tailscale";
    ssh.enable = lib.mkEnableOption "Tailscale SSH";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.autoconnect.enable -> cfg.autoconnect.keyFile != null;
        message = "khanelinix.services.tailscale.autoconnect.keyFile must be set";
      }
    ];

    environment.systemPackages = with pkgs; [
      tailscale
    ];

    networking = {
      firewall = {
        allowedTCPPorts = [ 5900 ];
        trustedInterfaces = [ config.services.tailscale.interfaceName ];
        # Strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups.
        checkReversePath = "loose";
      };

      networkmanager.unmanaged = [ "tailscale0" ];
    };

    services.tailscale = {
      # Tailscale documentation
      # See: https://tailscale.com/kb/
      enable = true;
      # Upstream does not send usage or logs to Tailscale with this set.
      disableUpstreamLogging = true;
      openFirewall = true;
      permitCertUid = "root";
      # "both" also enables the IPv4 and IPv6 forwarding sysctls that subnet
      # routing and exit nodes need.
      useRoutingFeatures = "both";
      # Read at runtime by upstream's tailscaled-autoconnect unit, which polls
      # BackendState instead of sleeping.
      authKeyFile = lib.mkIf cfg.autoconnect.enable cfg.autoconnect.keyFile;
      extraSetFlags = [
        "--operator=${config.khanelinix.user.name}"
        "--accept-routes=${lib.boolToString cfg.acceptRoutes}"
        "--advertise-exit-node=${lib.boolToString cfg.advertiseExitNode}"
        "--ssh=${lib.boolToString cfg.ssh.enable}"
      ]
      ++ lib.optionals (cfg.advertiseRoutes != [ ]) [
        "--advertise-routes=${concatStringsSep "," cfg.advertiseRoutes}"
      ];
    };

    systemd.network.wait-online.ignoredInterfaces = [ config.services.tailscale.interfaceName ];
  };
}
