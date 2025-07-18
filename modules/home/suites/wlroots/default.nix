{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.wlroots;
in
{
  options.${namespace}.suites.wlroots = {
    enable = lib.mkEnableOption "common wlroots configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wdisplays
      wl-clipboard
      wl-clip-persist
      wlr-randr
      wl-screenrec
    ];

    khanelinix = {
      programs = {
        graphical = {
          addons = {
            # FIXME: breaks 1password
            # electron-support = mkDefault enabled;
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
        # NOTE: doesn't provide anything extra compared to nixos module
        # keyring = mkDefault enabled;
      };
    };

    # using nixos module
    services.network-manager-applet.enable = mkDefault true;
    services = {
      blueman-applet.enable = mkDefault true;
    };
  };
}
