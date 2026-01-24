{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.khanelinix) disabled enabled;

  cfg = config.khanelinix.programs.graphical.wms.niri;

  # Check if the Home Manager niri module exists (Linux only)
  niriAvailable = options ? programs.niri;
in
{
  options.khanelinix.programs.graphical.wms.niri = {
    enable = mkEnableOption "niri";
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Configuration to pass through to the niri module.";
    };
  };

  imports = [
    ./apps.nix
    ./binds.nix
    ./variables.nix
    ./workspace-rules.nix
    ./window-rules.nix
  ];

  config = mkIf cfg.enable (
    lib.mkMerge [
      # Common config that doesn't depend on programs.niri
      {
        home.packages = with pkgs; [
          grim
          light
          playerctl
          slurp
          swaybg
          wl-clipboard
        ];

        khanelinix = {
          programs = {
            graphical = {
              bars = {
                ashell = lib.mkDefault enabled;
                waybar = lib.mkDefault disabled;
              };

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

      # Programs.niri config (only when available)
      (lib.optionalAttrs niriAvailable {
        programs.niri.settings = {
          hotkey-overlay.skip-at-startup = true;
          input.focus-follows-mouse.enable = true;
        }
        // cfg.settings;
      })
    ]
  );
}
