{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable =
      mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {

    khanelinix = {
      desktop.addons = {
        # swappy = enabled;
        swaylock = enabled;
        # swaynotificationcenter = enabled;
        waybar = enabled;
        # wlogout = enabled;
      };

      security = {
        keyring = enabled;
      };
    };

    # using nixos module
    # services.network-manager-applet.enable = true;
    services.blueman-applet.enable = true;
  };
}
