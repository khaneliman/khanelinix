{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.wlroots;
in
{
  options.${namespace}.suites.wlroots = {
    enable = mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wdisplays
      wl-clipboard
      wlr-randr
      wl-screenrec
    ];

    khanelinix = {
      programs = {
        graphical = {
          addons = {
            electron-support = mkDefault enabled;
            swappy = mkDefault enabled;
            swaync = mkDefault enabled;
            wlogout = mkDefault enabled;
          };

          bars = {
            waybar = mkDefault enabled;
          };
        };
      };

      services = {
        cliphist = mkDefault enabled;
        keyring = mkDefault enabled;
      };
    };

    # using nixos module
    # services.network-manager-applet.enable = mkDefault true;
    services = {
      blueman-applet.enable = mkDefault true;
    };
  };
}
