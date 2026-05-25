{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.archetypes.home-lab;
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

        security = {
          enable = lib.mkDefault true;
          inherit (cfg) cacheAppdataDir;
        };

        self-hosted = {
          enable = lib.mkDefault true;
          inherit (cfg) appdataDir;
          dataDir = lib.mkDefault "/mnt/user/data";
        };
      };

      services.home-assistant = {
        enable = lib.mkDefault true;
        configDir = lib.mkDefault "${cfg.cacheAppdataDir}/home-assistant";
      };

      virtualisation.podman.enable = lib.mkDefault true;
    };
  };
}
