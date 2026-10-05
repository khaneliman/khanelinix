{ config, lib, ... }:
{
  config = lib.mkMerge [
    (lib.mkIf config.khanelinix.suites.self-hosted.enable {
      virtualisation.oci-containers.containers = {
        ah-webapp = {
          image = "ghcr.io/khaneliman/austin-horstman-webapp:latest";
          autoStart = true;
          # Port:
          # - 8088/tcp: app UI
          ports = [ "8088:8080" ];
          environment.TZ = "America/Chicago";
        };
        ah-webapp-dev = {
          image = "ghcr.io/khaneliman/austin-horstman-webapp:main";
          autoStart = true;
          # Port:
          # - 8099/tcp: dev web UI
          ports = [ "8099:80" ];
          environment.TZ = "America/Chicago";
        };
        timemachine = {
          image = "mbentley/timemachine";
          autoStart = true;
          volumes = [
            "/mnt/user/timemachine:/opt/khaneliman"
          ];
          environment = {
            VOLUME_SIZE_LIMIT = "4 T";
            TM_USERNAME = "khaneliman";
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
          extraOptions = [
            "--ip=192.168.4.2"
            "--network=br0"
          ];
        };
        profilarr.environment = {
          GIT_USER_NAME = "Khaneliman";
          GIT_USER_EMAIL = "khaneliman12@gmail.com";
        };
      };
    })
    (lib.mkIf config.khanelinix.suites.security.enable {
      services = {
        cloudflared.tunnels.KHANELIMANCOM = {
          credentialsFile = "/run/secrets/cloudflared/khanelimancom.json";
          default = "http_status:404";
        };
        vaultwarden = {
          environmentFile = "/run/secrets/vaultwarden/environment";
          config.DOMAIN = "https://vaultwarden.khaneliman.com";
        };
      };
    })
    (lib.mkIf config.khanelinix.suites.media-server.enable {
      services.photoprism = {
        passwordFile = "/run/secrets/photoprism/admin-password";
        databasePasswordFile = "/run/secrets/photoprism/database-password";
        settings.PHOTOPRISM_SITE_URL = "http://austinserver.local:2342/";
      };
      virtualisation.oci-containers.containers.qbittorrentvpn.environment.LAN_NETWORK = "192.168.4.0/22";
    })
    (lib.mkIf config.khanelinix.suites.observability.enable {
      services.grafana.settings.security.secret_key = "$__file{/run/secrets/grafana/secret-key}";
    })
  ];
}
