{ config, lib, ... }:
let
  appdata = config.khanelinix.suites.media-server.cacheAppdataDir;
  data = config.khanelinix.suites.media-server.dataDir;
  media = config.khanelinix.suites.media-server.mediaDir;
  nativeApps = [
    "jellyfin"
    "lidarr"
    "plex"
    "radarr"
    "sonarr"
    "tautulli"
  ];
in
{
  # Existing application state and NFS-created media belong to Unraid UID 99.
  users.users.media = {
    uid = 99;
    isSystemUser = true;
    group = "users";
    extraGroups = [
      "video"
      "render"
    ];
  };

  services = lib.mkMerge [
    (lib.genAttrs nativeApps (_: {
      user = "media";
      group = "users";
    }))
    {
      plex.dataDir = lib.mkForce "${appdata}/plex/Library/Application Support";
      jellyfin = {
        dataDir = lib.mkForce "${appdata}/binhex-jellyfin/data";
        configDir = lib.mkForce "${appdata}/binhex-jellyfin/config";
        cacheDir = lib.mkForce "${appdata}/binhex-jellyfin/cache";
        logDir = lib.mkForce "${appdata}/binhex-jellyfin/logs";
        hardwareAcceleration = {
          enable = true;
          type = "qsv";
          device = "/dev/dri/renderD128";
        };
      };
      tautulli = {
        configFile = "${appdata}/tautulli/config.ini";
        openFirewall = true;
      };
    }
  ];

  systemd.services = lib.mkMerge [
    (lib.genAttrs (nativeApps ++ [ "prowlarr" ]) (_: {
      unitConfig.RequiresMountsFor = [
        appdata
        data
        media
      ];
    }))
    (lib.genAttrs [ "lidarr" "radarr" "sonarr" ] (name: {
      serviceConfig.BindPaths = [
        "${data}:/data"
        "${appdata}/${name}:/config"
      ];
    }))
    {
      plex.serviceConfig.BindPaths = [
        "${media}:/data"
        "${appdata}/plex:/config"
      ];
      jellyfin.serviceConfig = {
        BindPaths = [
          "${media}:/media"
          "${appdata}/binhex-jellyfin:/config"
        ];
        # Render-node access relies on the supplementary host render group.
        PrivateUsers = lib.mkForce false;
      };
      prowlarr.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "media";
        Group = "users";
        # Keep the upstream /var/lib/prowlarr command and avoid its private
        # DynamicUser bind mount, which would change the existing ownership.
        BindPaths = [
          "${appdata}/prowlarr:/var/lib/prowlarr"
          "${appdata}/prowlarr:/config"
        ];
      };
      tautulli.serviceConfig = {
        BindPaths = [ "${appdata}/tautulli:/config" ];
        BindReadOnlyPaths = [
          ''"${appdata}/plex/Library/Application Support/Plex Media Server/Logs":/plexlogs''
        ];
      };
      radarr.serviceConfig.BindReadOnlyPaths = [ "${appdata}/binhex-qbittorrentvpn:/qbittorrent" ];
    }
  ];
}
