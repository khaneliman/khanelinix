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
    # First OCI migration batch: self-hosted web utilities and containerized
    # tooling. Legacy backends are kept as parity placeholders while we
    # finalize service ownership and secret handling.
    virtualisation.oci-containers.containers = {
      mongodb = {
        image = "mongo";
        autoStart = true;
        # Port:
        # - 27017/tcp: MongoDB API/transport
        ports = [ "27017:27017" ];
        volumes = [ "${appdataDir}/mongodb:/data/db" ];
        environment.TZ = "America/Chicago";
      };

      ah-webapp = {
        image = "ghcr.io/khaneliman/austin-horstman-webapp:latest";
        autoStart = true;
        # Ports:
        # - 8088/tcp: app UI
        # - 17443/tcp: app HTTPS
        ports = [
          "8088:80"
          "17443:443"
        ];
        environment.TZ = "America/Chicago";
      };

      ah-webapp-dev = {
        image = "ghcr.io/khaneliman/austin-horstman-webapp:master";
        autoStart = true;
        # Port:
        # - 8099/tcp: dev web UI
        ports = [ "8099:80" ];
        environment.TZ = "America/Chicago";
      };

      adminer = {
        image = "adminer";
        autoStart = true;
        # Port:
        # - 8585/tcp: adminer UI
        ports = [ "8585:8080" ];
        environment = {
          ADMINER_DESIGN = "dracula";
          TZ = "America/Chicago";
        };
      };

      dockersocket = {
        image = "ghcr.io/tecnativa/docker-socket-proxy:latest";
        autoStart = true;
        # Port:
        # - 2375/tcp: Docker API proxy endpoint
        ports = [ "2375:2375" ];
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
        environment = {
          CONTAINERS = "0";
          POST = "1";
          BUILD = "1";
          PUSH = "1";
          PULL = "1";
          DISTRIBUTION = "1";
          IMAGES = "1";
        };
      };

      cleanuparr = {
        image = "ghcr.io/cleanuparr/cleanuparr:latest";
        autoStart = true;
        # Port:
        # - 11011/tcp: Cleanarrr web UI
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
        # Port:
        # - 8191/tcp: flaresolverr API
        ports = [ "8191:8191" ];
        environment = {
          LOG_LEVEL = "info";
          TZ = "America/Chicago";
        };
      };

      huntarr = {
        image = "huntarr/huntarr:latest";
        autoStart = true;
        # Port:
        # - 9705/tcp: huntarr web UI
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
        # Port:
        # - 8001/tcp: reclaimerr web UI
        ports = [ "8001:8000" ];
        volumes = [ "${appdataDir}/reclaimerr:/app/data" ];
        environment.TZ = "America/Chicago";
      };

      # TODO: decide container or native migration path for Profilarr credentials.
      profilarr = {
        image = "santiagosayshey/profilarr:latest";
        autoStart = false;
        # Port:
        # - 6868/tcp: profilarr web UI
        ports = [ "6868:6868" ];
        volumes = [ "${appdataDir}/Profilarr:/config" ];
        environment = {
          GIT_USER_NAME = "Khaneliman";
          GIT_USER_EMAIL = "khaneliman12@gmail.com";
          PROFILARR_PAT = "REPLACE_ME_GITHUB_TOKEN";
          PUID = "99";
          PGID = "100";
          UMASK = "002";
          TZ = "America/Chicago";
        };
      };

      # Legacy container from Unraid VM-era stack; retained for visibility until a
      # replacement decision is made in the split-machine phase.
      mariadb = {
        image = "linuxserver/mariadb";
        autoStart = true;
        # Port:
        # - 3306/tcp: MariaDB TCP
        ports = [ "3306:3306" ];
        volumes = [ "${appdataDir}/mariadb:/config" ];
        environment = {
          PUID = "99";
          PGID = "100";
          MYSQL_ROOT_PASSWORD = "REPLACE_ME_MYSQL_ROOT_PASSWORD";
          TZ = "America/Chicago";
        };
      };

      postgres11 = {
        image = "postgres:11";
        autoStart = false;
        # Port:
        # - 5432/tcp: PostgreSQL TCP
        ports = [ "5432:5432" ];
        volumes = [ "/mnt/pool/appdata/postgres:/var/lib/postgresql/data" ];
        environment = {
          POSTGRES_PASSWORD = "REPLACE_ME_POSTGRES_PASSWORD";
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "postgres";
          TZ = "America/Chicago";
        };
      };

      pwm = {
        image = "fjudith/pwm";
        autoStart = true;
        # Port:
        # - 8282/tcp: Password Manager web UI
        ports = [ "8282:8080" ];
        volumes = [ "${appdataDir}/pwm:/usr/share/pwm" ];
        environment = {
          PWM_APPLICATIONFLAGS = "NoFileLock";
          TZ = "America/Chicago";
        };
      };

      organizrv2 = {
        image = "organizr/organizr";
        autoStart = true;
        # Port:
        # - 280/tcp: Organizr web UI (legacy front-end)
        ports = [ "280:80" ];
        volumes = [ "${appdataDir}/organizrv2:/config" ];
        environment = {
          branch = "master";
          PUID = "99";
          PGID = "100";
          TZ = "America/Chicago";
        };
      };

      # TODO: depends on Samba semantics and migration strategy for Mac backup hosts.
      timemachine = {
        image = "mbentley/timemachine";
        autoStart = false;
        volumes = [
          "${dataDir}/timemachine:/opt/khaneliman"
          "/usr/local/share/docker/tailscale_container_hook:/opt/unraid/tailscale"
        ];
        environment = {
          VOLUME_SIZE_LIMIT = "4 T";
          TM_USERNAME = "khaneliman";
          PASSWORD = "REPLACE_ME_TM_PASSWORD";
          ADVERTISED_HOSTNAME = "timemachine";
          CUSTOM_SMB_CONF = "false";
          CUSTOM_USER = "false";
          DEBUG_LEVEL = "1";
          MIMIC_MODEL = "TimeCapsule8,119";
          HIDE_SHARES = "no";
          TM_GROUPNAME = "timemachine";
          TM_UID = "1000";
          TM_GID = "1000";
          SET_PERMISSIONS = "false";
          SMB_INHERIT_PERMISSIONS = "no";
          SMB_NFS_ACES = "yes";
          SMB_METADATA = "stream";
          SMB_PORT = "445";
          SMB_VFS_OBJECTS = "acl_xattr fruit streams_xattr";
          WORKGROUP = "WORKGROUP";
          SHARE_NAME = "TimeMachine";
        };
      };

      wakapi = {
        image = "ghcr.io/muety/wakapi:2.13.1";
        autoStart = true;
        # Port:
        # - 5000/tcp: wakapi web/API
        ports = [ "5000:3000" ];
        volumes = [ "${appdataDir}/wakapi/data:/data" ];
        environment = {
          WAKAPI_PASSWORD_SALT = "REPLACE_ME_WAKAPI_PASSWORD_SALT";
          PORT = "5000";
          ENVIRONMENT = "prod";
          WAKAPI_ALLOW_SIGNUP = "true";
          WAKAPI_DISABLE_FRONTPAGE = "false";
          WAKAPI_EXPOSE_METRICS = "false";
          WAKAPI_MAIL_ENABLED = "false";
          WAKAPI_MAIL_SENDER = "Wakapi noreply@wakapi.dev";
          WAKAPI_MAIL_PROVIDER = "smtp";
          WAKAPI_MAIL_SMTP_HOST = "";
          WAKAPI_MAIL_SMTP_PORT = "";
          WAKAPI_MAIL_SMTP_USER = "";
          WAKAPI_MAIL_SMTP_PASS = "";
          WAKAPI_MAIL_SMTP_TLS = "false";
          TZ = "America/Chicago";
        };
      };

      yacht = {
        image = "selfhostedpro/yacht";
        autoStart = true;
        # Port:
        # - 8000/tcp: yacht web UI
        ports = [ "8000:8000" ];
        volumes = [
          "${appdataDir}/yacht:/config"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        environment = {
          ADMIN_EMAIL = "admin@yacht.local";
          PUID = "99";
          PGID = "100";
          TZ = "America/Chicago";
        };
      };

      seerr = {
        image = "ghcr.io/seerr-team/seerr:latest";
        autoStart = true;
        # Port:
        # - 5055/tcp: seerr web API/UI
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

    networking.firewall = lib.mkMerge [
      { allowedTCPPorts = [ ]; }

      {
        # dockersocket
        allowedTCPPorts = [ 2375 ];
      }

      {
        # ah-webapp
        allowedTCPPorts = [
          8088
          17443
        ];
      }

      {
        # ah-webapp-dev
        allowedTCPPorts = [ 8099 ];
      }

      {
        # adminer
        allowedTCPPorts = [ 8585 ];
      }

      {
        # cleanuparr
        allowedTCPPorts = [ 11011 ];
      }

      {
        # flaresolverr
        allowedTCPPorts = [ 8191 ];
      }

      {
        # huntarr
        allowedTCPPorts = [ 9705 ];
      }

      {
        # reclaimerr
        allowedTCPPorts = [ 8001 ];
      }

      {
        # profilarr
        allowedTCPPorts = [ 6868 ];
      }

      {
        # mariadb
        allowedTCPPorts = [ 3306 ];
      }

      {
        # postgres11
        allowedTCPPorts = [ 5432 ];
      }

      {
        # pwm
        allowedTCPPorts = [ 8282 ];
      }

      {
        # organizr
        allowedTCPPorts = [ 280 ];
      }

      {
        # wakapi
        allowedTCPPorts = [ 5000 ];
      }

      {
        # yacht
        allowedTCPPorts = [ 8000 ];
      }

      {
        # seerr
        allowedTCPPorts = [ 5055 ];
      }

      {
        # mongodb
        allowedTCPPorts = [ 27017 ];
      }
    ];
  };
}
