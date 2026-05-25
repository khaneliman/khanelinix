{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.suites.security;
  cacheAppdata = cfg.cacheAppdataDir;
in
{
  options.khanelinix.suites.security = {
    enable = lib.mkEnableOption "security and edge service suite";

    cacheAppdataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/cache/appdata";
      description = "Cache-backed application data directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      adguardhome = {
        enable = true;
        openFirewall = true;
      };

      cloudflared = {
        enable = true;
        tunnels.KHANELIMANCOM = {
          credentialsFile = "/run/secrets/cloudflared/khanelimancom.json";
          default = "http_status:404";
        };
      };

      nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
      };

      postgresql = {
        enable = true;
        dataDir = "${cacheAppdata}/postgresql";
        package = pkgs.postgresql_16;
      };

      vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        environmentFile = "/run/secrets/vaultwarden/environment";
        config = {
          DOMAIN = "https://vaultwarden.khaneliman.com";
          ROCKET_ADDRESS = "0.0.0.0";
          ROCKET_PORT = 8222;
        };
      };
    };

    virtualisation.oci-containers.containers.nginx-proxy-manager = {
      image = "jc21/nginx-proxy-manager:latest";
      autoStart = true;
      ports = [
        "1880:80"
        "18443:443"
        "7818:81"
      ];
      volumes = [
        "${cacheAppdata}/NginxProxyManager:/data"
        "${cacheAppdata}/NginxProxyManager/letsencrypt:/etc/letsencrypt"
      ];
    };

    networking.firewall.allowedTCPPorts = [
      8222
    ];
  };
}
