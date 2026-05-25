{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.services.home-assistant;
in
{
  options.khanelinix.services.home-assistant = {
    enable = lib.mkEnableOption "Home Assistant";

    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/pool/appdata/home-assistant";
      description = "Home Assistant configuration directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Restore a Home Assistant backup into this configDir during cutover before
    # depending on integrations. HAOS add-ons/supervisor features may still need
    # native NixOS services or OCI containers.
    services.home-assistant = {
      enable = true;
      inherit (cfg) configDir;
      openFirewall = true;

      extraComponents = [
        "default_config"
        "esphome"
        "met"
        "mobile_app"
        "mqtt"
        "radio_browser"
        "shopping_list"
        "ssdp"
        "thread"
        "usb"
        "zeroconf"
      ];

      config = {
        homeassistant = {
          name = "Home";
          unit_system = "us_customary";
          time_zone = "America/Chicago";
        };

        http = {
          server_host = "0.0.0.0";
          server_port = 8123;
        };
      };
    };
  };
}
