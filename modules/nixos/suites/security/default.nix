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
        # Exposes DNS and web ports via module defaults.
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
      # Ports:
      # - 1880/tcp: NPM web UI
      # - 18443/tcp: TLS termination endpoint
      # - 7818/tcp: NPM admin endpoint
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

    # Legacy Unraid auth edge service retained until an equivalent NixOS-native
    # ingress/auth strategy is finalized.
    virtualisation.oci-containers.containers.authelia = {
      image = "authelia/authelia";
      autoStart = false;
      # Port:
      # - 9091/tcp: Authelia auth UI/API
      ports = [ "9091:9091" ];
      volumes = [ "/mnt/user/appdata/Authelia:/config" ];
      environment = {
        TZ = "America/Chicago";
        X_AUTHELIA_CONFIG = "/config/configuration.yml";
        PUID = "99";
        PGID = "100";
      };
    };

    networking.firewall = lib.mkMerge [
      { allowedTCPPorts = [ ]; }

      {
        # vaultwarden
        allowedTCPPorts = [ 8222 ];
      }

      {
        # nginx-proxy-manager
        allowedTCPPorts = [
          1880
          18443
          7818
        ];
      }

      {
        # authelia
        allowedTCPPorts = [ 9091 ];
      }
    ];
  };
}
