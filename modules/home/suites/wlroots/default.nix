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
  waylandSessionStop = pkgs.writeShellScriptBin "wayland-session-stop" ''
    set -u

    stop_hyprland() {
      command -v hyprctl >/dev/null 2>&1 && hyprctl dispatch exit && exit 0
    }

    stop_sway() {
      command -v swaymsg >/dev/null 2>&1 && swaymsg exit && exit 0
    }

    stop_niri() {
      command -v niri >/dev/null 2>&1 && niri msg action quit && exit 0
    }

    desktop="''${XDG_CURRENT_DESKTOP:-}"

    case "$desktop" in
      *Hyprland* | *hyprland*) stop_hyprland ;;
      *Sway* | *sway*) stop_sway ;;
      *Niri* | *niri*) stop_niri ;;
    esac

    [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && stop_hyprland
    [ -n "''${SWAYSOCK:-}" ] && stop_sway
    [ -n "''${NIRI_SOCKET:-}" ] && stop_niri

    if [ -n "''${XDG_SESSION_ID:-}" ]; then
      exec loginctl terminate-session "$XDG_SESSION_ID"
    fi

    echo "wayland-session-stop: XDG_SESSION_ID is unset" >&2
    exit 1
  '';
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
        waylandSessionStop
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
          voxtype = mkDefault enabled;
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
