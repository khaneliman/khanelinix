{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable = mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {

    khanelinix = {
      programs = {
        graphical = {
          addons = {
            swaync = enabled;
            wlogout = enabled;
          };

          bars = {
            waybar = enabled;
          };
        };
      };

      services = {
        keyring = enabled;
        polkit = enabled;
      };
    };

    # using nixos module
    # services.network-manager-applet.enable = true;
    services = {
      blueman-applet.enable = true;

      cliphist = {
        enable = true;
        allowImages = true;
      };
    };
  };
}
