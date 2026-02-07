{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    types
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.theme.stylix;
  fontCfg = config.khanelinix.fonts;
  themeCfg = config.khanelinix.theme;

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
      "superfile"
      "television"
      "tmux"
      "vesktop"
      "vicinae"
      "zathura"
      "zellij"
      # Wayland/Linux specific
      "gnome"
      "hyprland"
      "qt"
      "sway"
      "waybar"
    ];
    nord = [
      "alacritty"
      "ghostty"
      "helix"
      "kitty"
      "neovim"
      "superfile"
      "television"
      "tmux"
      "vicinae"
      "wezterm"
      "yazi"
    ];
    tokyonight = [
      "alacritty"
      "bat"
      "btop"
      "cava"
      "delta"
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
      "superfile"
      "television"
      "tmux"
      "vesktop"
      "vicinae"
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

  anyCuratedTheme = themeCfg.catppuccin.enable || themeCfg.nord.enable || themeCfg.tokyonight.enable;
in
{
  options.khanelinix.theme.stylix = {
    enable = mkEnableOption "stylix theme for applications";
    theme = mkOpt types.str "catppuccin-macchiato" "base16 theme file name";

    cursor = {
      name = mkOpt types.str "catppuccin-macchiato-blue-cursors" "The name of the cursor theme to apply.";
      package = mkOpt types.package (
        if pkgs.stdenv.hostPlatform.isLinux then
          pkgs.catppuccin-cursors.macchiatoBlue
        else
          pkgs.emptyDirectory
      ) "The package to use for the cursor theme.";
      size = mkOpt types.int 32 "The size of the cursor.";
    };

    icon = {
      name = mkOpt types.str "Papirus-Dark" "The name of the icon theme to apply.";
      package = mkOpt types.package (pkgs.catppuccin-papirus-folders.override {
        accent = "blue";
        flavor = "macchiato";
      }) "The package to use for the icon theme.";
    };
  };

  config = mkIf cfg.enable (
    lib.optionalAttrs (lib.hasAttrByPath [ "stylix" ] options) {
      # Each theme sets their own pointerCursor
      home = mkIf (pkgs.stdenv.hostPlatform.isLinux && !anyCuratedTheme) {
        pointerCursor = {
          inherit (cfg.cursor) name package size;
        };
      };

      # Each theme has its own fonts
      gtk.gtk3 = mkIf pkgs.stdenv.hostPlatform.isLinux {
        font = null;
      };

      stylix = {
        enable = true;
        # autoEnable = false;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.theme}.yaml";

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

        icons = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          enable = true;
          inherit (cfg.icon) package;
          dark = cfg.icon.name;
          # TODO: support custom light
          light = cfg.icon.name;
        };

        polarity = "dark";

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
          tmux.enable = !(isThemedBy "tmux");
          vesktop.enable = !(isThemedBy "vesktop");
          vicinae.enable = !(isThemedBy "vicinae");
          wezterm.enable = !(isThemedBy "wezterm");
          yazi.enable = !(isThemedBy "yazi");
          zathura.enable = !(isThemedBy "zathura");
          zellij.enable = !(isThemedBy "zellij");
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          gnome.enable = !(isThemedBy "gnome");
          # FIXME: not working
          gtk.enable = false;
          hyprland.enable = !(isThemedBy "hyprland");
          # FIXME:: upstream needs module fix
          hyprlock.useWallpaper = false;
          hyprlock.enable = false;
          qt.enable = !(isThemedBy "qt");
          sway.enable = !(isThemedBy "sway");
          # TODO: Very custom styling, integrate with their variables
          # Currently setup only for catppuccin/nix
          swaync.enable = false;
          waybar.enable = !(isThemedBy "waybar");
        };
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        cursor = lib.mkOptionDefault cfg.cursor;
      };
    }
  );
}
