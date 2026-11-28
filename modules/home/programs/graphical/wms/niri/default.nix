{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.khanelinix) enabled;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.khanelinix.programs.graphical.wms.niri;
  useSystemNiri = osConfig.programs.niri.enable or false;
in
{
  options.khanelinix.programs.graphical.wms.niri = {
    enable = mkEnableOption "niri";
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        KDL settings passed through to `wayland.windowManager.niri.settings`.

        See <https://niri-wm.github.io/niri/Configuration%3A-Introduction.html>
      '';
    };
  };

  imports = [
    ./apps.nix
    ./binds.nix
    ./variables.nix
    ./workspace-rules.nix
    ./window-rules.nix
  ];

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "Niri is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) (
      lib.mkMerge [
        {
          wayland.windowManager.niri = {
            enable = true;
            # Match the compositor the NixOS session runs so validation and
            # `niri msg` use the same version.
            package = lib.mkDefault (osConfig.programs.niri.package or pkgs.niri);
            settings = {
              hotkey-overlay.skip-at-startup = { };
              input.focus-follows-mouse = { };
              # An absolute path keeps Xwayland working without relying on
              # niri's PATH.
              xwayland-satellite.path = lib.getExe config.wayland.windowManager.niri.xwaylandSatellitePackage;
            };
          };

          home.packages = with pkgs; [
            grim
            brightnessctl
            playerctl
            slurp
            swaybg
            wl-clipboard
          ];

          khanelinix = {
            programs = {
              graphical = {
                launchers = {
                  anyrun = enabled;
                  vicinae = enabled;
                };

                screenlockers = {
                  swaylock = enabled;
                };
              };
            };

            suites = {
              wlroots = enabled;
            };

            theme = {
              gtk = enabled;
              qt = enabled;
            };
          };

          khanelinix.services.niri-wallpaper-watch = {
            enable = true;
            wallpapers = lib.khanelinix.theme.wallpaperPaths {
              inherit config pkgs;
              names = config.khanelinix.theme.wallpaper.list;
            };
          };
        }

        { wayland.windowManager.niri.settings = cfg.settings; }

        # The NixOS module already provides the session units and portals.
        (mkIf useSystemNiri {
          wayland.windowManager.niri = {
            systemd.enable = false;
            portalPackage = null;
          };
        })
      ]
    ))
  ];
}
