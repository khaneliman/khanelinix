{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrByPath
    mkEnableOption
    mkIf
    mkMerge
    optionalAttrs
    optionalString
    ;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

  cfg = config.khanelinix.programs.graphical.apps.teams-for-linux;
in
{
  options.khanelinix.programs.graphical.apps.teams-for-linux = {
    enable = mkEnableOption "Teams for Linux";
  };

  config = mkIf cfg.enable (
    let
      catppuccin = import (lib.getFile "modules/home/theme/catppuccin/colors.nix");
      nord = import (lib.getFile "modules/home/theme/nord/colors.nix");
      tokyonight = import (lib.getFile "modules/home/theme/tokyonight/colors.nix");

      themeEnabled = {
        catppuccin = config.khanelinix.theme.catppuccin.enable;
        nord = config.khanelinix.theme.nord.enable;
        tokyonight = config.khanelinix.theme.tokyonight.enable;
      };

      autoTheme =
        let
          enabledThemes = builtins.filter (name: themeEnabled.${name}) [
            "catppuccin"
            "nord"
            "tokyonight"
          ];
        in
        if enabledThemes == [ ] then "none" else builtins.head enabledThemes;

      tokyonightVariant = attrByPath [ "khanelinix" "theme" "tokyonight" "variant" ] "night" config;

      themePalettes = {
        catppuccin = {
          bg = catppuccin.colors.base.hex;
          surface = catppuccin.colors.surface0.hex;
          surfaceAlt = catppuccin.colors.mantle.hex;
          fg = catppuccin.colors.text.hex;
          muted = catppuccin.colors.subtext0.hex;
          accent = catppuccin.colors.blue.hex;
          accentSoft = catppuccin.colors.sapphire.hex;
          border = catppuccin.colors.overlay0.hex;
        };
        nord = {
          bg = nord.palette.nord0.hex;
          surface = nord.palette.nord1.hex;
          surfaceAlt = nord.palette.nord2.hex;
          fg = nord.palette.nord6.hex;
          muted = nord.palette.nord4.hex;
          accent = nord.palette.nord10.hex;
          accentSoft = nord.palette.nord8.hex;
          border = nord.palette.nord3.hex;
        };
        tokyonight =
          let
            colors = tokyonight.getVariant tokyonightVariant;
          in
          {
            inherit (colors) bg fg;
            surface = colors.bg_dark;
            surfaceAlt = colors.bg_highlight;
            muted = colors.comment;
            accent = colors.blue;
            accentSoft = colors.cyan;
            border = colors.blue7;
          };
      };

      themePalette = themePalettes.${autoTheme} or null;

      themeCss = optionalString (themePalette != null) /* css */ ''
        :root {
          --khanelinix-teams-bg: ${themePalette.bg};
          --khanelinix-teams-surface: ${themePalette.surface};
          --khanelinix-teams-surface-alt: ${themePalette.surfaceAlt};
          --khanelinix-teams-fg: ${themePalette.fg};
          --khanelinix-teams-muted: ${themePalette.muted};
          --khanelinix-teams-accent: ${themePalette.accent};
          --khanelinix-teams-accent-soft: ${themePalette.accentSoft};
          --khanelinix-teams-border: ${themePalette.border};
        }

        html,
        body,
        #app,
        .app,
        .ts-main,
        .fui-FluentProvider {
          background-color: var(--khanelinix-teams-bg) !important;
          color: var(--khanelinix-teams-fg) !important;
        }

        .fui-Card,
        .fui-DialogSurface,
        .fui-PopoverSurface,
        .fui-MenuPopover,
        [role="dialog"] {
          background-color: var(--khanelinix-teams-surface) !important;
          border-color: var(--khanelinix-teams-border) !important;
          color: var(--khanelinix-teams-fg) !important;
        }

        .fui-Button,
        .fui-Tab,
        .fui-Input,
        .fui-Combobox {
          border-color: var(--khanelinix-teams-border) !important;
        }

        .fui-Button:hover,
        .fui-Tab:hover {
          background-color: var(--khanelinix-teams-surface-alt) !important;
        }

        .fui-Button[aria-pressed="true"],
        .fui-Tab[aria-selected="true"] {
          background-color: var(--khanelinix-teams-accent) !important;
          color: var(--khanelinix-teams-bg) !important;
        }

        a {
          color: var(--khanelinix-teams-accent-soft) !important;
        }
      '';

      configDir =
        if isLinux then
          "${config.xdg.configHome}/teams-for-linux"
        else
          "${config.home.homeDirectory}/Library/Application Support/teams-for-linux";

      hasCustomCss = themeCss != "";

      settings = {
        appIdleTimeout = 7200;
        appIdleTimeoutCheckInterval = 30;
        appActiveCheckInterval = 5;
        awayOnSystemIdle = false;

        followSystemTheme = false;
        trayIconEnabled = true;
        notificationMethod = "electron";
        disableNotificationSound = false;

        wayland = {
          xwaylandOptimizations = true;
        };

        media.camera.autoAdjustAspectRatio.enabled = true;
      }
      // (optionalAttrs hasCustomCss {
        customCSSLocation = "${configDir}/custom.css";
      });
    in
    {
      home.packages = [ pkgs.teams-for-linux ];

      xdg.configFile = mkIf isLinux (mkMerge [
        {
          "teams-for-linux/config.json".text = builtins.toJSON settings;
        }
        (mkIf hasCustomCss {
          "teams-for-linux/custom.css".text = themeCss;
        })
      ]);

      home.file = mkIf isDarwin (mkMerge [
        {
          "Library/Application Support/teams-for-linux/config.json".text = builtins.toJSON settings;
        }
        (mkIf hasCustomCss {
          "Library/Application Support/teams-for-linux/custom.css".text = themeCss;
        })
      ]);
    }
  );
}
