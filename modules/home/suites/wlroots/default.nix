{
  config,
  lib,
  osConfig ? { },

  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) enabled;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable = lib.mkEnableOption "common wlroots configuration";
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "wlroots is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) {
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
              satty = mkDefault enabled;
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
          wl-clip-persist = mkDefault enabled;
          # NOTE: doesn't provide anything extra compared to nixos module
          # keyring = mkDefault enabled;
        };
      };

      # using nixos module
      services.network-manager-applet.enable = mkDefault true;
      services = {
        blueman-applet.enable = mkDefault (
          !(osConfig.services.blueman.enable or false) || !(osConfig.services.blueman.withApplet or true)
        );
      };
    })
  ];
}
