{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
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
            name = "catppuccin-macchiato-blue-standard";
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
              accent = "blue";
              variant = "macchiato";
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
      # NOTE: Need some customization and merging of configuration files so cant just enable all
      enable = false;

      accent = "blue";
      flavor = "macchiato";
    };

    home = {
      file = mkMerge [
        (mkIf config.khanelinix.programs.terminal.emulators.warp.enable {
          ".warp/themes/catppuccin_macchiato.yaml".source = warpStyle;
          ".local/share/warp-terminal/themes/catppuccin_macchiato.yaml".source = warpStyle;
        })
        (mkIf pkgs.stdenv.isDarwin {
          "Library/Application Support/BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
        })
      ];

      pointerCursor = mkIf pkgs.stdenv.isLinux {
        inherit (config.${namespace}.theme.gtk.cursor) name package size;
        x11.enable = true;
      };

      sessionVariables = mkIf pkgs.stdenv.isLinux {
        CURSOR_THEME = config.${namespace}.theme.gtk.cursor.name;
      };
    };

    qt = mkIf pkgs.stdenv.isLinux {
      enable = true;

      platformTheme = {
        name = "qtct";
      };

      style = {
        name = "kvantum";
        inherit (config.${namespace}.theme.qt.theme) package;
      };
    };

    wayland.windowManager.hyprland.catppuccin =
      mkIf config.${namespace}.programs.graphical.wms.hyprland.enable
        {
          enable = true;

          inherit (cfg) accent;
        };

    wayland.windowManager.sway = {
      catppuccin = mkIf config.${namespace}.programs.graphical.wms.sway.enable { enable = true; };

      config.colors = {
        background = "$base";

        focused = {
          childBorder = "$lavender";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          border = "$lavender";
        };

        focusedInactive = {
          childBorder = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          border = "$overlay0";
        };

        unfocused = {
          childBorder = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$rosewater";
          border = "$overlay0";
        };

        urgent = {
          childBorder = "$peach";
          background = "$base";
          text = "$peach";
          indicator = "$overlay0";
          border = "$peach";
        };

        placeholder = {
          childBorder = "$overlay0";
          background = "$base";
          text = "$text";
          indicator = "$overlay0";
          border = "$overlay0";
        };

        # bar
        # focusedBackground = "$base";
        # focusedStatusline = "$text";
        # focusedSeparator = "$base";
        # focusedWorkspace = {
        #   border = "$base";
        #   background = "$base";
        #   text = "$green";
        # };
        #
        # activeWorkspace = {
        #   border = "$base";
        #   background = "$base";
        #   text = "$blue";
        # };
        #
        # inactiveWorkspace = {
        #   border = "$base";
        #   background = "$base";
        #   text = "$surface1";
        # };
        #
        # urgentWorkspace = {
        #   border = "$base";
        #   background = "$base";
        #   text = "$peach";
        # };
        #
        # bindingMode = {
        #   border = "$base";
        #   background = "$base";
        #   text = "$surface1";
        # };
      };
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
          "foot"
          "fzf"
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
        ncspot.settings = {
          theme = {
            background = "#24273A";
            primary = "#CAD3F5";
            secondary = "#1E2030";
            title = "#8AADF4";
            playing = "#8AADF4";
            playing_selected = "#B7BDF8";
            playing_bg = "#181926";
            highlight = "#C6A0F6";
            highlight_bg = "#494D64";
            error = "#CAD3F5";
            error_bg = "#ED8796";
            statusbar = "#181926";
            statusbar_progress = "#CAD3F5";
            statusbar_bg = "#8AADF4";
            cmdline = "#CAD3F5";
            cmdline_bg = "#181926";
            search_match = "#f5bde6";
          };
        };

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
          (import ./yazi/manager.nix { inherit config lib namespace; })
          (import ./yazi/status.nix { })
          (import ./yazi/theme.nix { })
        ];

        # TODO: Make work with personal customizations
        # yazi.catppuccin.enable = true;
        # rofi.catppuccin.enable = true;
      };

    xdg.configFile =
      mkIf (pkgs.stdenv.isLinux && config.${namespace}.programs.graphical.apps.discord.enable)
        {
          "ArmCord/themes/Catppuccin-Macchiato-BD".source = ./Catppuccin-Macchiato-BD;
          "BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
        };
  };
}
