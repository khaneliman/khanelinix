{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.${namespace}) capitalize;

  cfg = config.${namespace}.theme.catppuccin;

  warpPkg = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "warp";
    rev = "11295fa7aed669ca26f81ff44084059952a2b528";
    hash = "sha256-ym5hwEBtLlFe+DqMrXR3E4L2wghew2mf9IY/1aynvAI=";
  };

  warpStyle = "${warpPkg.outPath}/themes/catppuccin_macchiato.yml";

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

  catppuccinFlavors = [
    "latte"
    "frappe"
    "macchiato"
    "mocha"
  ];
in
{
  options.${namespace}.theme.catppuccin = {
    enable = mkEnableOption "Enable catppuccin theme for applications.";

    accent = mkOption {
      type = types.enum catppuccinAccents;
      default = "blue";
      description = ''
        An optional theme accent.
      '';
    };

    flavor = mkOption {
      type = types.enum catppuccinFlavors;
      default = "macchiato";
      description = ''
        An optional theme flavor.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.catppuccin.override {
        inherit (cfg) accent;
        variant = cfg.flavor;
      };
    };
  };

  config = mkIf cfg.enable {
    khanelinix = {
      theme = {
        gtk = mkIf pkgs.stdenv.isLinux {
          cursor = {
            name = "catppuccin-macchiato-blue-cursors";
            package = pkgs.catppuccin-cursors.macchiatoBlue;
            size = 32;
          };

          icon = {
            name = "Papirus-Dark";
            package = pkgs.catppuccin-papirus-folders.override {
              accent = "blue";
              flavor = "macchiato";
            };
          };

          theme = {
            name = "catppuccin-macchiato-blue-standard+normal";
            package = pkgs.catppuccin-gtk.override {
              accents = [ "blue" ];
              variant = "macchiato";
            };
          };
        };

        qt = mkIf pkgs.stdenv.isLinux {
          theme = {
            name = "Catppuccin-Macchiato-Blue";
            package = pkgs.catppuccin-kvantum.override {
              accent = "Blue";
              variant = "Macchiato";
            };
          };

          settings = {
            Appearance = {
              color_scheme_path = "${pkgs.catppuccin}/qt5ct/Catppuccin-${capitalize cfg.flavor}.conf";
            };
          };
        };
      };
    };

    catppuccin = {
      # NOTE: getting infinite recursion error with global enable
      enable = false;

      accent = "blue";
      flavor = "macchiato";
    };

    home = {
      file = mkIf config.khanelinix.programs.terminal.emulators.warp.enable {
        ".warp/themes/catppuccin_macchiato.yaml".source = warpStyle;
        ".local/share/warp-terminal/themes/catppuccin_macchiato.yaml".source = warpStyle;
      };

      pointerCursor = mkIf pkgs.stdenv.isLinux {
        inherit (config.${namespace}.theme.gtk.cursor) name package size;
        x11.enable = true;
      };

      sessionVariables = mkIf pkgs.stdenv.isLinux {
        CURSOR_THEME = config.${namespace}.theme.gtk.cursor.name;
      };
    };

    gtk.catppuccin = mkIf pkgs.stdenv.isLinux {
      enable = true;

      inherit (cfg) accent;
      size = "standard";

      cursor = {
        enable = true;
        inherit (cfg) accent;
      };

      icon = {
        enable = true;
        inherit (cfg) accent;
      };
    };

    qt = mkIf pkgs.stdenv.isLinux {
      enable = true;

      platformTheme = {
        name = "qtct";
      };

      style = {
        name = "qt6ct-style";
        inherit (config.${namespace}.theme.qt.theme) package;
      };
    };

    wayland.windowManager.hyprland.catppuccin = mkIf pkgs.stdenv.isLinux {
      enable = true;

      inherit (cfg) accent;
    };

    programs =
      let
        applyCatppuccin =
          {
            name,
            nestedName ? null,
            extraAttrs ? { },
          }:
          let
            catppuccinConfig = {
              catppuccin = {
                enable = true;
                inherit (cfg) flavor;
              } // extraAttrs;
            };
          in
          if nestedName == null then
            {
              inherit name;
              value = catppuccinConfig;
            }
          else
            {
              inherit name;
              value = {
                ${nestedName} = catppuccinConfig;
              };
            };

        themedPrograms = map (prog: applyCatppuccin { name = prog; }) [
          "alacritty"
          "bat"
          "bottom"
          "btop"
          "cava"
          "fish"
          "fzf"
          "foot"
          "gh-dash"
          "gitui"
          "glamour"
          "helix"
          "kitty"
          "neovim"
          "waybar"
          "zathura"
          "zellij"
        ];

        extraConfigurations = [
          (applyCatppuccin {
            name = "git";
            nestedName = "delta";
          })
          (applyCatppuccin {
            name = "k9s";
            extraAttrs = {
              transparent = true;
            };
          })
          (applyCatppuccin {
            name = "lazygit";
            extraAttrs = {
              inherit (cfg) accent;
            };
          })
          (applyCatppuccin {
            name = "zsh";
            nestedName = "syntaxHighlighting";
          })
        ];

        allPrograms = themedPrograms ++ extraConfigurations;

        programs = builtins.listToAttrs allPrograms;
      in
      programs
      // {
        # Additional program settings that don't follow the common pattern
        tmux.plugins = [
          {
            plugin = pkgs.tmuxPlugins.catppuccin;
            extraConfig = ''
              set -g @catppuccin_flavour '${cfg.flavor}'
              set -g @catppuccin_host 'on'
              set -g @catppuccin_user 'on'
            '';
          }
        ];

        yazi.theme = lib.mkMerge [
          (import ./yazi/filetype.nix { })
          (import ./yazi/icons.nix { })
          (import ./yazi/manager.nix { inherit config lib namespace; })
          (import ./yazi/status.nix { })
          (import ./yazi/theme.nix { })
        ];

        # TODO: Make work with personal customizations
        # yazi.catppuccin.enable = true;
        # rofi.catppuccin.enable = true;
      };
  };
}
