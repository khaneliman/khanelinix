{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.suites.observability;
  cacheAppdata = cfg.cacheAppdataDir;
in
{
  options.khanelinix.suites.observability = {
    enable = lib.mkEnableOption "observability suite";

    cacheAppdataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/cache/appdata";
      description = "Cache-backed application data directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      systembus-notify.enable = lib.mkForce true;

      grafana = {
        enable = true;
        dataDir = "${cacheAppdata}/grafana";
        settings.server = {
          http_addr = "0.0.0.0";
          http_port = 3000;
        };
        settings.security.secret_key = "$__file{/run/secrets/grafana/secret-key}";
      };

      scrutiny = {
        enable = true;
        openFirewall = true;
      };

      uptime-kuma = {
        enable = true;
        settings.HOST = "0.0.0.0";
      };
    };

    networking.firewall.allowedTCPPorts = [
      3000
    ];
  };
}
