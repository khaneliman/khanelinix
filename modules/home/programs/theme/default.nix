{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.desktop.theme;

  catppuccinAccents = [
    "rosewater"
    "flamingo"
    "pink"
    "mauve"
    "red"
    "maroon"
    "peach"
    "yellow"
    "green"
    "teal"
    "sky"
    "sapphire"
    "blue"
    "lavender"
  ];
  catppuccinVariants = [
    "latte"
    "frappe"
    "macchiato"
    "mocha"
  ];
in
{
  options.khanelinix.desktop.theme = {
    enable = mkEnableOption "Enable custom theme use for applications.";

    cursor = {
      name = mkOpt types.str "Catppuccin-Macchiato-Blue-Cursors" "The name of the cursor theme to apply.";
      package = mkOpt types.package (
        if pkgs.stdenv.isLinux then pkgs.catppuccin-cursors.macchiatoBlue else pkgs.emptyDirectory
      ) "The package to use for the cursor theme.";
      size = mkOpt types.int 32 "The size of the cursor.";
    };

    icon = {
      name = mkOpt types.str "breeze-dark" "The name of the icon theme to apply.";
      package = mkOpt types.package pkgs.libsForQt5.breeze-icons "The package to use for the icon theme.";
    };

    selectedTheme = mkOption {
      type = types.submodule {
        options = {
          name = mkOpt types.str "catppuccin" "The theme to use.";
          accent = mkOption {
            type = types.enum catppuccinAccents;
            default = "blue";
            description = ''
              An optional theme accent.
            '';
          };
          variant = mkOption {
            type = types.enum catppuccinVariants;
            default = "macchiato";
            description = ''
              An optional theme variant.
            '';
          };
        };
      };
      default = {
        name = "catppuccin";
        accent = "blue";
        variant = "macchiato";
      };
      description = "Theme to use for applications.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.catppuccin.override { inherit (cfg.selectedTheme) accent variant; };
      description = ''
        The `spotifyd` package to use.
        Can be used to specify extensions.
      '';
    };
  };

  config = mkIf cfg.enable {
    catppuccin = {
      enable = false;

      accent = "blue";
      flavor = "macchiato";
    };

    home = mkIf pkgs.stdenv.isLinux {
      pointerCursor = {
        inherit (cfg.cursor) name package size;
        x11.enable = true;
      };

      sessionVariables = {
        CURSOR_THEME = cfg.cursor.name;
      };
    };

    gtk.catppuccin = {
      enable = true;

      inherit (cfg.selectedTheme) accent;
      size = "standard";

      cursor = {
        enable = true;
        inherit (cfg.selectedTheme) accent;
      };

      icon = {
        enable = true;
        inherit (cfg.selectedTheme) accent;
      };
    };

    wayland.windowManager.hyprland.catppuccin = {
      enable = true;

      inherit (cfg.selectedTheme) accent;
    };

    programs = {
      bat.catppuccin.enable = true;
      bottom.catppuccin.enable = true;
      btop.catppuccin.enable = true;
      cava.catppuccin.enable = true;
      fish.catppuccin.enable = true;
      fzf.catppuccin.enable = true;
      git.delta.catppuccin.enable = true;
      gh-dash.catppuccin.enable = true;
      gitui.catppuccin.enable = true;
      glamour.catppuccin.enable = true;
      helix.catppuccin.enable = true;

      k9s.catppuccin = {
        enable = true;

        transparent = true;
      };

      kitty.catppuccin.enable = true;

      lazygit.catppuccin = {
        enable = true;

        inherit (cfg.selectedTheme) accent;
      };

      neovim.catppuccin.enable = true;
      waybar.catppuccin.enable = true;

      zathura.catppuccin.enable = true;
      zellij.catppuccin.enable = true;
      zsh.syntaxHighlighting.catppuccin.enable = true;

      # TODO: Make work with personal customizations
      # yazi.catppuccin.enable = true;
      # rofi.catppuccin.enable = true;
      tmux.plugins = [
        {
          plugin = pkgs.tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavour '${cfg.selectedTheme.variant}'
            set -g @catppuccin_host 'on'
            set -g @catppuccin_user 'on'
          '';
        }
      ];
    };
  };
}
