{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.archetypes.home-lab;
  cacheAppdata = cfg.cacheAppdataDir;
in
{
  options.khanelinix.archetypes.home-lab = {
    enable = lib.mkEnableOption "home lab archetype";

    appdataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/user/appdata";
      description = "Persistent application data directory.";
    };

    cacheAppdataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/cache/appdata";
      description = "Cache-backed application data directory.";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/user/data/media";
      description = "Media library root.";
    };
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {
      suites = {
        media-server = {
          enable = lib.mkDefault true;
          inherit (cfg) appdataDir cacheAppdataDir mediaDir;
        };

        nas.enable = lib.mkDefault true;

        observability = {
          enable = lib.mkDefault true;
          inherit (cfg) cacheAppdataDir;
        };
      };

      virtualisation.podman.enable = lib.mkDefault true;
    };

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

    virtualisation.oci-containers = {
      backend = "podman";
      containers.nginx-proxy-manager = {
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
    };

    networking.firewall.allowedTCPPorts = [
      8222
    ];
  };
}
