{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.desktop-environment.plasma;
  catppuccinCfg = config.khanelinix.theme.catppuccin;
  cursorCfg = config.khanelinix.theme.gtk.cursor;

  capitalize = s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (-1) s;

  wallpaperPath = name: lib.khanelinix.theme.wallpaperPath { inherit config pkgs name; };
in
{
  options.khanelinix.programs.graphical.desktop-environment.plasma = {
    enable = lib.mkEnableOption "KDE Plasma desktop environment customization";

    panel = {
      launchers = mkOpt (types.listOf types.str) [
        "applications:org.kde.dolphin.desktop"
        "applications:org.kde.konsole.desktop"
        "applications:firefox.desktop"
        "applications:steam.desktop"
      ] "Apps pinned to the panel task manager.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.optionals catppuccinCfg.enable [
      (pkgs.catppuccin-kde.override {
        flavour = [ catppuccinCfg.flavor ];
        accents = [ catppuccinCfg.accent ];
      })
    ];

    programs.plasma = {
      enable = true;

      workspace = {
        wallpaper = wallpaperPath config.khanelinix.theme.wallpaper.primary;

        colorScheme = mkIf catppuccinCfg.enable "Catppuccin${capitalize catppuccinCfg.flavor}${capitalize catppuccinCfg.accent}";
        lookAndFeel = mkIf catppuccinCfg.enable "Catppuccin-${capitalize catppuccinCfg.flavor}-${capitalize catppuccinCfg.accent}";

        cursor = mkIf (cursorCfg.name != null) {
          theme = cursorCfg.name;
          inherit (cursorCfg) size;
        };
      };

      panels = [
        {
          location = "bottom";
          height = 48;
          floating = true;
          widgets = [
            {
              kickoff = {
                icon = "nix-snowflake-white";
              };
            }
            {
              iconTasks = {
                inherit (cfg.panel) launchers;
              };
            }
            "org.kde.plasma.marginsseparator"
            {
              systemTray.items.shown = [
                "org.kde.plasma.volume"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.bluetooth"
              ];
            }
            {
              digitalClock = {
                calendar.firstDayOfWeek = "sunday";
                time.format = "12h";
              };
            }
            "org.kde.plasma.showdesktop"
          ];
        }
      ];

      kwin = {
        effects = {
          desktopSwitching.animation = "slide";
          minimization.animation = "squash";
        };
      };

      # Double-tap Meta opens the launcher; Meta+W matches GNOME-style overview
      shortcuts.kwin."Overview" = "Meta+W";
    };
  };
}
