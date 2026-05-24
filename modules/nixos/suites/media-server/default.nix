{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.suites.media-server;
  appdata = cfg.appdataDir;
  cacheAppdata = cfg.cacheAppdataDir;
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

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/user/data/media";
      description = "Media library root.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl."vm.overcommit_memory" = lib.mkForce 1;

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
        openFirewall = true;
      };

      jellyfin = {
        enable = true;
        cacheDir = "${cacheAppdata}/jellyfin/cache";
        configDir = "${cacheAppdata}/jellyfin/config";
        dataDir = "${cacheAppdata}/jellyfin/data";
        logDir = "${cacheAppdata}/jellyfin/log";
        openFirewall = true;
      };

      lidarr = {
        enable = true;
        dataDir = "${cacheAppdata}/lidarr";
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
        openFirewall = true;
      };

      prowlarr = {
        enable = true;
        openFirewall = true;
      };

      qbittorrent = {
        enable = true;
        openFirewall = true;
        profileDir = "${cacheAppdata}/qbittorrent";
        torrentingPort = 6881;
        webuiPort = 8082;
      };

      radarr = {
        enable = true;
        dataDir = "${cacheAppdata}/radarr";
        openFirewall = true;
      };

      readarr = {
        enable = true;
        dataDir = "${cacheAppdata}/readarr";
        openFirewall = true;
      };

      redis.servers.khanelilab = {
        enable = true;
        openFirewall = true;
        port = 6379;
      };

      sonarr = {
        enable = true;
        dataDir = "${cacheAppdata}/sonarr";
        openFirewall = true;
      };

      tautulli = {
        enable = true;
        dataDir = "${cacheAppdata}/tautulli";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${appdata} 0775 ${config.khanelinix.user.name} users -"
      "d ${cacheAppdata} 0775 ${config.khanelinix.user.name} users -"
      "d ${media} 0775 ${config.khanelinix.user.name} users -"
    ];
  };
}
