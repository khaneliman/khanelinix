{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.suites.self-hosted;
  inherit (cfg) appdataDir dataDir;
in
{
  options.khanelinix.suites.self-hosted = {
    enable = lib.mkEnableOption "self-hosted application suite";

    appdataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/user/appdata";
      description = "Application data root.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/user/data";
      description = "User data root.";
    };
  };

  config = lib.mkIf cfg.enable {
    # First OCI migration batch: stateless/simple web apps and appdata-backed
    # services that do not need secret values declared in Nix. Database-backed,
    # VPN, Docker-socket, and secret-heavy containers stay out until their
    # credentials and dependency order are made explicit.
    virtualisation.oci-containers.containers = {
      ah-webapp = {
        image = "ghcr.io/khaneliman/austin-horstman-webapp:latest";
        autoStart = true;
        ports = [
          "8088:80"
          "17443:443"
        ];
        environment.TZ = "America/Chicago";
      };

      ah-webapp-dev = {
        image = "ghcr.io/khaneliman/austin-horstman-webapp:master";
        autoStart = true;
        ports = [ "8099:80" ];
        environment.TZ = "America/Chicago";
      };

      adminer = {
        image = "adminer";
        autoStart = true;
        ports = [ "8585:8080" ];
        environment = {
          ADMINER_DESIGN = "dracula";
          TZ = "America/Chicago";
        };
      };

      cleanuparr = {
        image = "ghcr.io/cleanuparr/cleanuparr:latest";
        autoStart = true;
        ports = [ "11011:11011" ];
        volumes = [
          "${appdataDir}/Cleanuparr:/config"
          "${dataDir}/torrents:/downloads"
        ];
        environment = {
          PUID = "99";
          PGID = "100";
          TZ = "America/Chicago";
          UMASK = "002";
        };
      };

      flaresolverr = {
        image = "flaresolverr/flaresolverr";
        autoStart = true;
        ports = [ "8191:8191" ];
        environment = {
          LOG_LEVEL = "info";
          TZ = "America/Chicago";
        };
      };

      huntarr = {
        image = "huntarr/huntarr:latest";
        autoStart = true;
        ports = [ "9705:9705" ];
        volumes = [ "${appdataDir}/Huntarr:/config" ];
        environment = {
          PUID = "99";
          PGID = "100";
          TZ = "America/Chicago";
        };
      };

      reclaimerr = {
        image = "ghcr.io/jessielw/reclaimerr:latest";
        autoStart = true;
        ports = [ "8001:8000" ];
        volumes = [ "${appdataDir}/reclaimerr:/app/data" ];
        environment.TZ = "America/Chicago";
      };

      seerr = {
        image = "ghcr.io/seerr-team/seerr:latest";
        autoStart = true;
        ports = [ "5055:5055" ];
        volumes = [
          "${appdataDir}/overseerr:/app/config"
          "${appdataDir}/overseerr/logs:/app/config/logs"
        ];
        environment = {
          LOG_LEVEL = "info";
          PORT = "5055";
          TZ = "America/Chicago";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      5055
      8001
      8088
      8099
      8191
      8585
      9705
      11011
      17443
    ];
  };
}
