{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.system.networking;
in
{
  config = mkIf (cfg.dns == "systemd-resolved") {
    services.resolved = {
      enable = true;

      # dnssec = "true";
      # this is necessary to get tailscale picking up your headscale instance
      # and allows you to ping connected hosts by hostname
      domains = [ "~." ];
      dnsovertls = "true";
      # extraConfig =
      #   mkIf cfg.dns == "dnsmasq" ''
      #     DNSStubListener=false
      #   '';
      fallbackDns = [ "192.168.1.1" ];
    };
  };
}
