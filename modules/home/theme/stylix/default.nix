{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? { },
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    types
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.theme.stylix;
  fontCfg = config.khanelinix.fonts;
  themeCfg = config.khanelinix.theme;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  themeApps = {
    catppuccin = [
      "alacritty"
      "bat"
      "btop"
      "cava"
      "fish"
      "foot"
      "fzf"
      "ghostty"
      "gitui"
      "helix"
      "k9s"
      "kitty"
      "lazygit"
      "ncspot"
      "neovim"
      "opencode"
      "tmux"
      "vesktop"
      "wezterm"
      "yazi"
      "zathura"
      "zellij"
      # Wayland/Linux specific
      "gnome"
      "hyprland"
      "qt"
      "sway"
    ];
    nord = [
      "alacritty"
      "ghostty"
      "helix"
      "kitty"
      "neovim"
      "tmux"
      "wezterm"
      "yazi"
      # Wayland/Linux specific
      "qt"
    ];
    tokyonight = [
      "alacritty"
      "bat"
      "btop"
      "cava"
      "fish"
      "foot"
      "fzf"
      "ghostty"
      "gitui"
      "helix"
      "kitty"
      "lazygit"
      "ncspot"
      "neovim"
      "opencode"
      "tmux"
      "vesktop"
      "wezterm"
      "yazi"
      "zathura"
      "zellij"
      # Wayland/Linux specific
      "hyprland"
      "qt"
      "sway"
    ];
  };

  isThemedBy =
    app:
    lib.any (theme: themeCfg.${theme}.enable && lib.elem app themeApps.${theme}) [
      "catppuccin"
      "nord"
      "tokyonight"
    ];

  fallback = (import ../catppuccin/colors.nix).colors;
  fallbackPalette = {
    accent = fallback.blue.hex;
    accentForeground = fallback.base.hex;
    background = fallback.base.hex;
    border = fallback.surface1.hex;
    danger = fallback.red.hex;
    foreground = fallback.text.hex;
    muted = fallback.subtext0.hex;
    orange = fallback.peach.hex;
    pink = fallback.pink.hex;
    secondary = fallback.teal.hex;
    shadow = fallback.crust.hex;
    subtle = fallback.overlay2.hex;
    success = fallback.green.hex;
    surface = fallback.surface0.hex;
    surfaceRaised = fallback.surface0.hex;
    tertiary = fallback.mauve.hex;
    warning = fallback.yellow.hex;
  };
  graphical = config.khanelinix.programs.graphical;
  stylixPalette = config.lib.stylix.colors.withHashtag;

  anyCuratedTheme = themeCfg.catppuccin.enable || themeCfg.nord.enable || themeCfg.tokyonight.enable;
  curatedPolarity =
    if
      (themeCfg.tokyonight.enable && themeCfg.tokyonight.variant == "day")
      || (themeCfg.catppuccin.enable && themeCfg.catppuccin.flavor == "latte")
    then
      "light"
    else
      "dark";
in
{
  options.khanelinix.theme.active = lib.mkOption {
    type = types.submodule {
      options = lib.mapAttrs (
        role: _:
        lib.mkOption {
          type = types.strMatching "#[0-9a-fA-F]{6}";
          description = "Active theme color for ${role}.";
        }
      ) fallbackPalette;
    };
    internal = true;
    default =
      if config.stylix.enable or false then
        {
          accent = stylixPalette.base0D;
          accentForeground = stylixPalette.base00;
          background = stylixPalette.base00;
          border = stylixPalette.base03;
          danger = stylixPalette.base08;
          foreground = stylixPalette.base05;
          # Base16 does not guarantee that base04 is readable as text, so it
          # only backs subtle, which draws de-emphasized icons.
          muted = stylixPalette.base05;
          orange = stylixPalette.base09;
          # Base16 has no pink, so pink repeats the purple that backs tertiary.
          pink = stylixPalette.base0E;
          secondary = stylixPalette.base0C;
          shadow = stylixPalette.base01;
          subtle = stylixPalette.base04;
          success = stylixPalette.base0B;
          surface = stylixPalette.base01;
          surfaceRaised = stylixPalette.base02;
          tertiary = stylixPalette.base0E;
          warning = stylixPalette.base0A;
        }
      else
        fallbackPalette;
    description = "Semantic colors shared by the desktop configuration.";
  };

  options.khanelinix.theme.stylix = {
    enable = mkEnableOption "stylix theme for applications";
    theme = mkOpt types.str "catppuccin-macchiato" "base16 theme file name";

    cursor = {
      name =
        mkOpt types.str "catppuccin-macchiato-blue-cursors"
          "The home fallback cursor theme; a followed system cursor takes precedence.";
      package = mkOpt types.package (
        if pkgs.stdenv.hostPlatform.isLinux then
          pkgs.catppuccin-cursors.macchiatoBlue
        else
          pkgs.emptyDirectory
      ) "The home fallback cursor package; a followed system cursor takes precedence.";
      size =
        mkOpt types.int 32
          "The home fallback cursor size; a followed system cursor takes precedence.";
    };

    icon = {
      name = mkOpt types.str "Papirus-Dark" "The name of the icon theme to apply.";
      package = mkOpt types.package (
        if isLinux then
          pkgs.catppuccin-papirus-folders.override {
            accent = "blue";
            flavor = "macchiato";
          }
        else
          pkgs.emptyDirectory
      ) "The package to use for the icon theme.";
    };
  };

  config = lib.mkMerge [
    (mkIf (isLinux && (config.stylix.enable or false)) {
      khanelinix.theme.gtk.cursor = mkIf ((config.stylix.cursor or null) != null) {
        name = mkDefault config.stylix.cursor.name;
        package = mkDefault config.stylix.cursor.package;
        size = mkDefault (builtins.floor (config.stylix.cursor.size + 0.5));
      };

      stylix.targets = {
        ashell.enable = lib.mkIf graphical.bars.ashell.enable false;
        rofi.enable = lib.mkIf graphical.launchers.rofi.enable false;
        swaylock.enable = lib.mkIf graphical.screenlockers.swaylock.enable false;
        vicinae.enable = lib.mkIf graphical.launchers.vicinae.enable false;
        waybar.enable = lib.mkIf graphical.bars.waybar.enable false;
        wofi.enable = lib.mkIf graphical.launchers.wofi.enable false;
      };
    })
    (mkIf graphical.launchers.vicinae.enable {
      programs.vicinae = {
        settings.theme = {
          light.name = mkDefault "khanelinix";
          dark.name = mkDefault "khanelinix";
        };

        themes.khanelinix =
          let
            colors = themeCfg.active;
            variant =
              if anyCuratedTheme then
                curatedPolarity
              else if (config.stylix.polarity or "dark") == "light" then
                "light"
              else
                "dark";
          in
          {
            meta = {
              name = "Khanelinix";
              # Vicinae rejects a theme whose meta table lacks a description.
              description = "Colors from the active khanelinix theme.";
              inherit variant;
              inherits = "vicinae-${variant}";
            };
            colors = {
              core = {
                inherit (colors)
                  background
                  foreground
                  border
                  accent
                  ;
                secondary_background = colors.surface;
              };
              accents = {
                blue = colors.accent;
                cyan = colors.secondary;
                green = colors.success;
                magenta = colors.pink;
                inherit (colors) orange;
                purple = colors.tertiary;
                red = colors.danger;
                yellow = colors.warning;
              };
              grid.item.background = colors.surfaceRaised;
              list.item = {
                hover.background = {
                  name = colors.surfaceRaised;
                  opacity = 0.6;
                };
                selection = {
                  background = colors.surfaceRaised;
                  secondary_background = colors.surfaceRaised;
                };
              };
            };
          };
      };
    })
    (mkIf cfg.enable {
      stylix = {
        enable = true;
        # autoEnable = false;
        base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/${cfg.theme}.yaml";

        fonts = {
          sizes = {
            desktop = 11;
            applications = 12;
            terminal = 13;
            popups = 12;
          };

          serif = {
            package = pkgs.monaspace;
            name = fontCfg.monaspace.families.neon;
          };
          sansSerif = {
            package = pkgs.monaspace;
            name = fontCfg.monaspace.families.neon;
          };
          monospace = {
            package = pkgs.monaspace;
            name = fontCfg.monaspace.families.krypton;
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };

        icons = lib.mkIf isLinux {
          enable = true;
          inherit (cfg.icon) package;
          dark = cfg.icon.name;
          # TODO: support custom light
          light = cfg.icon.name;
        };

        polarity = lib.mkIf anyCuratedTheme curatedPolarity;

        opacity = {
          desktop = 1.0;
          applications = 0.90;
          terminal = 0.90;
          popups = 1.0;
        };

        # ╭──────────────────────────────────────────────────────────╮
        # │     Prefer custom themes over generic color palette      │
        # │   Check which themes support which feature and toggle    │
        # ╰──────────────────────────────────────────────────────────╯
        targets = {
          firefox.profileNames = [ config.khanelinix.user.name ];

          # TODO: Very custom styling, integrate with their variables
          # Currently setup only for catppuccin/nix
          vscode.enable = false;

          alacritty.enable = !(isThemedBy "alacritty");
          bat.enable = !(isThemedBy "bat");
          btop.enable = !(isThemedBy "btop");
          cava.enable = !(isThemedBy "cava");
          fish.enable = !(isThemedBy "fish");
          foot.enable = !(isThemedBy "foot");
          fzf.enable = !(isThemedBy "fzf");
          ghostty.enable = !(isThemedBy "ghostty");
          gitui.enable = !(isThemedBy "gitui");
          helix.enable = !(isThemedBy "helix");
          k9s.enable = !(isThemedBy "k9s");
          kitty = {
            enable = !(isThemedBy "kitty");
          };
          lazygit.enable = !(isThemedBy "lazygit");
          ncspot.enable = !(isThemedBy "ncspot");
          neovim.enable = !(isThemedBy "neovim");
          opencode.enable = !(isThemedBy "opencode");
          tmux.enable = !(isThemedBy "tmux");
          vesktop.enable = !(isThemedBy "vesktop");
          wezterm.enable = !(isThemedBy "wezterm");
          yazi.enable = !(isThemedBy "yazi");
          zathura.enable = !(isThemedBy "zathura");
          zellij.enable = !(isThemedBy "zellij");
        }
        // lib.optionalAttrs isLinux {
          gnome.enable = !(isThemedBy "gnome");
          # FIXME: not working
          gtk.enable = false;
          hyprland.enable = !(isThemedBy "hyprland");
          # FIXME:: upstream needs module fix
          hyprlock.image.enable = false;
          hyprlock.enable = false;
          qt.enable = !(isThemedBy "qt");
          sway.enable = !(isThemedBy "sway");
          # TODO: Very custom styling, integrate with their variables
          # Currently setup only for catppuccin/nix
          swaync.enable = false;
        }
        // lib.optionalAttrs (!isLinux) {
          gtk.enable = false;
          qt.enable = false;
        };

        cursor = lib.mkIf isLinux (
          if anyCuratedTheme then
            lib.mkForce null
          else
            let
              inheritsNullCursor =
                (osConfig.stylix.enable or false)
                && (osConfig.stylix.homeManagerIntegration.autoImport or false)
                && (osConfig.stylix.homeManagerIntegration.followSystem or false)
                && (osConfig.stylix.cursor or null) == null;
            in
            # A null system default must not suppress the enabled home fallback.
            lib.mkOverride (if inheritsNullCursor then 900 else 1100) cfg.cursor
        );
      };

      # GTK font overrides are only relevant when Home Manager manages GTK.
      gtk.gtk3 = lib.mkIf isLinux {
        font = null;
      };
    })
  ];
}
