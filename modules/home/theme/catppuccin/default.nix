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

  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.theme.catppuccin;
in
{
  imports = [
    ./firefox.nix
    ./gtk.nix
    ./qt.nix
    ./sway.nix
  ];

  options.${namespace}.theme.catppuccin = {
    enable = mkEnableOption "Enable catppuccin theme for applications.";

    accent = mkOption {
      type = types.enum [
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
      default = "blue";
      description = ''
        An optional theme accent.
      '';
    };

    flavor = mkOption {
      type = types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
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
    catppuccin = {
      # NOTE: Need some customization and merging of configuration files so cant just enable all
      enable = false;

      accent = "blue";
      flavor = "macchiato";

      alacritty = enabled;
      bat = enabled;
      bottom = enabled;
      btop = enabled;
      cava = enabled;
      delta = enabled;
      fish = enabled;
      foot = enabled;
      fzf = enabled;
      gh-dash = enabled;
      ghostty = enabled;
      gitui = enabled;
      glamour = enabled;
      helix = enabled;
      k9s = {
        enable = true;
        transparent = true;
      };
      kitty = enabled;
      lazygit = {
        enable = true;
        inherit (cfg) accent;
      };
      nvim = enabled;
      waybar = enabled;
      zathura = enabled;
      zellij = enabled;
      zsh-syntax-highlighting = enabled;
      sway.enable = true;

      hyprland = mkIf config.${namespace}.programs.graphical.wms.hyprland.enable {
        enable = true;

        inherit (cfg) accent;
      };

      # TODO: Make work with personal customizations
      # yazi.enable = true;
      # rofi.enable = true;
    };

    home = {
      file = mkMerge [
        (
          let
            warpPkg = pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "warp";
              rev = "11295fa7aed669ca26f81ff44084059952a2b528";
              hash = "sha256-ym5hwEBtLlFe+DqMrXR3E4L2wghew2mf9IY/1aynvAI=";
            };

            warpStyle = "${warpPkg.outPath}/themes/catppuccin_macchiato.yml";
          in
          mkIf config.khanelinix.programs.terminal.emulators.warp.enable {
            ".warp/themes/catppuccin_macchiato.yaml".source = warpStyle;
            ".local/share/warp-terminal/themes/catppuccin_macchiato.yaml".source = warpStyle;
          }
        )
        (mkIf pkgs.stdenv.isDarwin {
          "Library/Application Support/BetterDiscord/themes/catppuccin-macchiato.theme.css".source =
            ./catppuccin-macchiato.theme.css;
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

    programs = {
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
    };

    xdg.configFile =
      mkIf (pkgs.stdenv.isLinux && config.${namespace}.programs.graphical.apps.discord.enable)
        {
          "ArmCord/themes/Catppuccin-Macchiato-BD".source = ./Catppuccin-Macchiato-BD;
          "BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
        };
  };
}
