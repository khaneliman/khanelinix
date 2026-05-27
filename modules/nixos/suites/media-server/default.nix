{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce;

  cfg = config.khanelinix.suites.media-server;
  appdata = cfg.appdataDir;
  cacheAppdata = cfg.cacheAppdataDir;
  inherit (cfg) dataDir;
  media = cfg.mediaDir;
in
{
  options.khanelinix.suites.media-server = {
    enable = lib.mkEnableOption "media server suite";

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

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/user/data";
      description = "Container data root for legacy compatibility.";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/user/data/media";
      description = "Media library root.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Preserve the Unraid-era media container mix until native equivalents are
    # stable enough for cutover.
    boot.kernel.sysctl."vm.overcommit_memory" = mkForce 1;

    # Native qBittorrent is replaced by the VPN container for ISP policy.
    services.qbittorrent.enable = mkForce false;

    environment.systemPackages = with pkgs; [
      cifs-utils
      ffmpeg
      intel-gpu-tools
      libva-utils
      pciutils
    ];

    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];

    khanelinix.virtualisation.podman.enable = lib.mkDefault true;

    services = {
      bazarr = {
        enable = true;
        dataDir = "${cacheAppdata}/bazarr";
        # Container-equivalent port is the bazarr module default.
        openFirewall = true;
      };

      jellyfin = {
        enable = true;
        cacheDir = "${cacheAppdata}/jellyfin/cache";
        configDir = "${cacheAppdata}/jellyfin/config";
        dataDir = "${cacheAppdata}/jellyfin/data";
        logDir = "${cacheAppdata}/jellyfin/log";
        # Container-equivalent port is the jellyfin module default.
        openFirewall = true;
      };

      lidarr = {
        enable = true;
        dataDir = "${cacheAppdata}/lidarr";
        # Container-equivalent port is the lidarr module default.
        openFirewall = true;
      };

      photoprism = {
        enable = true;
        address = "0.0.0.0";
        originalsPath = "${media}/photoprism";
        importPath = "${media}/familyphotos";
        storagePath = "${cacheAppdata}/photoprism";
        passwordFile = "/run/secrets/photoprism/admin-password";
        databasePasswordFile = "/run/secrets/photoprism/database-password";
        settings.PHOTOPRISM_SITE_URL = "http://austinserver.local:2342/";
      };

      plex = {
        enable = true;
        dataDir = "${cacheAppdata}/plex";
        # Container-equivalent port is the plex module default.
        openFirewall = true;
      };

      prowlarr = {
        enable = true;
        # Container-equivalent port is the prowlarr module default.
        openFirewall = true;
      };

      radarr = {
        enable = true;
        dataDir = "${cacheAppdata}/radarr";
        # Container-equivalent port is the radarr module default.
        openFirewall = true;
      };

      readarr = {
        enable = true;
        dataDir = "${cacheAppdata}/readarr";
        # Container-equivalent port is the readarr module default.
        openFirewall = true;
      };

      redis.servers.khanelilab = {
        enable = true;
        # Redis service port is exposed on default TCP 6379.
        openFirewall = true;
        port = 6379;
      };

      sonarr = {
        enable = true;
        dataDir = "${cacheAppdata}/sonarr";
        # Container-equivalent port is the sonarr module default.
        openFirewall = true;
      };

      tautulli = {
        enable = true;
        dataDir = "${cacheAppdata}/tautulli";
      };
    };

    virtualisation.oci-containers.containers = {
      # TODO: keep legacy qBittorrent path layout temporarily for parity with /mnt.
      qbittorrentvpn = {
        image = "binhex/arch-qbittorrentvpn";
        autoStart = true;
        # Ports:
        # - 6881/tcp, 6881/udp: peer wireguard/BitTorrent ingress
        # - 8082: web UI
        # - 8119: private bittorrent port-forward target
        ports = [
          "6881:6881/tcp"
          "6881:6881/udp"
          "8082:8082/tcp"
          "8119:8119/tcp"
        ];
        volumes = [
          "${appdata}/binhex-qbittorrentvpn:/config"
          "${dataDir}:/data"
          "${appdata}/binhex-qbittorrentvpn/vuetorrent:/vuetorrent"
        ];
        environment = {
          VPN_ENABLED = "yes";
          VPN_USER = "REPLACE_ME_VPN_USER";
          VPN_PASS = "REPLACE_ME_VPN_PASS";
          VPN_PROV = "pia";
          VPN_CLIENT = "wireguard";
          VPN_OPTIONS = "";
          VPN_OUTPUT_PORTS = "";
          VPN_INPUT_PORTS = "";
          STRICT_PORT_FORWARD = "yes";
          ENABLE_PRIVOXY = "no";
          WEBUI_PORT = "8082";
          LAN_NETWORK = "192.168.4.0/24";
          NAME_SERVERS = "209.222.18.222,84.200.69.80,37.235.1.174,1.1.1.1,209.222.18.218,37.235.1.177,84.200.70.40,1.0.0.1";
          DEBUG = "false";
          UMASK = "000";
          PUID = "99";
          PGID = "100";
          TZ = "America/Chicago";
        };
        extraOptions = [
          "--privileged"
          "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        ];
      };

      # Legacy immich DB sidecar kept to avoid an immediate migration of DB and ML
      # workloads; move this to native PostgreSQL when we can codify restore
      # and replication workflows.
      postgresql_immich = {
        image = "ghcr.io/immich-app/postgres:16-vectorchord0.4.3-pgvectors0.2.0";
        autoStart = true;
        # Port:
        # - 5433/tcp: PostgreSQL for immich workload
        ports = [ "5433:5432" ];
        volumes = [ "${appdata}/PostgreSQL_Immich:/var/lib/postgresql/data" ];
        extraOptions = [
          "-m"
          "8GB"
        ];
        environment = {
          POSTGRES_PASSWORD = "REPLACE_ME_IMMICH_DB_PASSWORD";
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "immich";
          TZ = "America/Chicago";
        };
      };

      # TODO: DB/redis hostnames are explicit here for compatibility; they should be
      # moved to service-discovery style wiring during future container migration.
      immich = {
        image = "ghcr.io/imagegenius/immich:latest";
        autoStart = true;
        # Port:
        # - 8081/tcp: web/API endpoint for immich media service
        ports = [ "8081:8080" ];
        volumes = [
          "${media}/immich:/photos"
          "${media}/pictures:/import:ro"
          "${media}/pictures:/pictures"
          "${appdata}/immich:/config"
        ];
        environment = {
          DB_HOSTNAME = "192.168.4.42";
          DB_USERNAME = "postgres";
          DB_PASSWORD = "REPLACE_ME_IMMICH_DB_PASSWORD";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "192.168.4.42";
          DB_PORT = "5433";
          REDIS_PORT = "6379";
          REDIS_PASSWORD = "";
          MACHINE_LEARNING_GPU_ACCELERATION = "";
          MACHINE_LEARNING_WORKERS = "1";
          MACHINE_LEARNING_WORKER_TIMEOUT = "120";
          PUID = "99";
          PGID = "100";
          UMASK = "022";
          TZ = "America/Chicago";
        };
      };

      maintainerr = {
        image = "jorenn92/maintainerr:latest";
        autoStart = true;
        # Port:
        # - 8154/tcp: maintainerr UI/API
        ports = [ "8154:6246" ];
        volumes = [ "${appdata}/maintainerr:/opt/data" ];
        environment = {
          TZ = "America/Chicago";
        };
      };

      stash = {
        image = "stashapp/stash";
        autoStart = true;
        # Port:
        # - 6969/tcp: Stash web UI
        ports = [ "6969:9999" ];
        volumes = [
          "${media}/shadowplay/temp/local/AppData/temp:/data"
          "${media}/shadowplay/temp/local/AppData/temp2:/data2"
          "${appdata}/stash/config:/root/.stash"
          "${appdata}/stash/metadata:/metadata"
          "${appdata}/stash/cache:/cache"
          "${appdata}/stash/generated:/generated"
        ];
        environment = {
          STASH_STASH = "/data/";
          STASH_CACHE = "/cache/";
          STASH_METADATA = "/metadata/";
          STASH_GENERATED = "/generated/";
        };
      };

      imagemaid = {
        image = "kometateam/imagemaid";
        autoStart = true;
        volumes = [
          "${appdata}/ImageMaid:/config"
          "${cacheAppdata}/plex/Library/Application Support/Plex Media Server:/plex"
        ];
        environment = {
          MODE = "report";
          PLEX_PATH = "";
          PLEX_URL = "";
          PLEX_TOKEN = "";
          LOCAL_DB = "False";
          IGNORE_RUNNING = "False";
          USE_EXISTING = "False";
          PHOTO_TRANSCODER = "False";
          EMPTY_TRASH = "False";
          CLEAN_BUNDLES = "False";
          OPTIMIZE_DB = "False";
          OVERLAYS_ONLY = "False";
          DISCORD = "";
          TIMEOUT = "600";
          NO_VERIFY_SSL = "False";
          SLEEP = "60";
          TRACE = "False";
          LOG_REQUESTS = "False";
          SCHEDULE = "";
        };
      };

      qdirstat = {
        image = "jlesage/qdirstat";
        autoStart = true;
        # Ports:
        # - 7815/tcp: web UI
        # - 7915/tcp: VNC viewer for qdirstat container
        ports = [
          "7815:5800"
          "7915:5900"
        ];
        volumes = [
          "/mnt/user:/storage:ro"
          "${appdata}/QDirStat:/config"
        ];
        environment = {
          USER_ID = "99";
          GROUP_ID = "100";
          UMASK = "0000";
          APP_NICENESS = "0";
          DISPLAY_WIDTH = "1920";
          DISPLAY_HEIGHT = "1080";
          DARK_MODE = "0";
          WEB_AUDIO = "0";
          WEB_FILE_MANAGER = "0";
          WEB_FILE_MANAGER_ALLOWED_PATHS = "AUTO";
          WEB_FILE_MANAGER_DENIED_PATHS = "None";
          WEB_NOTIFICATION = "0";
          WEB_AUTHENTICATION = "0";
          WEB_AUTHENTICATION_TOKEN_VALIDITY_TIME = "24";
          WEB_AUTHENTICATION_USERNAME = "";
          WEB_AUTHENTICATION_PASSWORD = "";
          SECURE_CONNECTION = "0";
          SECURE_CONNECTION_VNC_METHOD = "SSL";
          SECURE_CONNECTION_CERTS_CHECK_INTERVAL = "60";
          WEB_LISTENING_PORT = "5800";
          VNC_LISTENING_PORT = "5900";
        };
      };

      "kometa-ls" = {
        image = "lscr.io/linuxserver/kometa";
        autoStart = true;
        volumes = [ "${appdata}/Kometa:/config" ];
        environment = {
          KOMETA_CONFIG = "/config/config.yml";
          KOMETA_TIME = "03:00";
          KOMETA_RUN = "False";
          KOMETA_TEST = "False";
          KOMETA_NO_MISSING = "False";
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
      };

      "tinymm-gui-v5" = {
        image = "tinymediamanager/tinymediamanager:latest";
        autoStart = true;
        # Ports:
        # - 4066/tcp: Tiny Media Manager web UI
        # - 5966/tcp: VNC interface
        ports = [
          "4066:4000"
          "5966:5900"
        ];
        volumes = [
          "${appdata}/TMM5:/data"
          "${media}/movies:/media/movies"
          "${media}/tv:/media/tv-shows"
        ];
        environment = {
          PASSWORD = "";
          ALLOW_DIRECT_VNC = "true";
          TZ = "America/Chicago";
          PUID = "99";
          USER_ID = "99";
          GUID = "100";
          UMASK = "000";
          LC_ALL = "en_US.UTF-8";
          LANG = "en_US.UTF-8";
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${appdata} 0775 ${config.khanelinix.user.name} users -"
      "d ${cacheAppdata} 0775 ${config.khanelinix.user.name} users -"
      "d ${dataDir} 0775 ${config.khanelinix.user.name} users -"
      "d ${media} 0775 ${config.khanelinix.user.name} users -"
    ];

    networking.firewall = lib.mkMerge [
      {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      }

      {
        # qbittorrentvpn
        allowedTCPPorts = [
          6881
          8082
          8119
        ];
        allowedUDPPorts = [ 6881 ];
      }

      {
        # immich sidecars + service
        allowedTCPPorts = [
          5433
          8081
        ];
      }

      {
        # maintainerr
        allowedTCPPorts = [ 8154 ];
      }

      {
        # stash
        allowedTCPPorts = [ 6969 ];
      }

      {
        # qdirstat
        allowedTCPPorts = [
          7815
          7915
        ];
      }

      {
        # tinymm-gui-v5
        allowedTCPPorts = [
          4066
          5966
        ];
      }
    ];
  };
}
