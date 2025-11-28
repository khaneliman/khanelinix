{
  config,
  lib,
  pkgs,
  inputs,
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

  inherit (lib.khanelinix) enabled;

  palette = import ./colors.nix;

  cfg = config.khanelinix.theme.catppuccin;
in
{
  imports = [
    ./firefox.nix
    ./gtk.nix
    ./oh-my-posh.nix
    ./qt.nix
    ./sway.nix
  ];

  options.khanelinix.theme.catppuccin = {
    enable = mkEnableOption "catppuccin theme for applications";

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

  config = mkIf cfg.enable (
    lib.mkMerge [
      (lib.optionalAttrs (inputs ? catppuccin && inputs.catppuccin ? homeModules) {
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
          hyprland = mkIf config.khanelinix.programs.graphical.wms.hyprland.enable {
            enable = true;
            inherit (cfg) accent;
          };
          k9s = {
            enable = true;
            transparent = true;
          };
          kitty = enabled;
          kvantum = {
            enable = true;
            inherit (cfg) accent;
          };
          lazygit = {
            enable = true;
            inherit (cfg) accent;
          };
          nvim = enabled;
          sway = enabled;
          thunderbird = {
            enable = true;
            profile = config.khanelinix.user.name;
          };
          vicinae.enable = pkgs.stdenv.hostPlatform.isLinux;
          waybar = enabled;
          zathura = enabled;
          zellij = enabled;
          zsh-syntax-highlighting = enabled;
        };
      })

      {
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
            (mkIf pkgs.stdenv.hostPlatform.isDarwin {
              # TODO: use packaged version
              "Library/Application Support/BetterDiscord/themes/catppuccin-macchiato.theme.css".source =
                ./catppuccin-macchiato.theme.css;
            })
          ];

          pointerCursor = mkIf pkgs.stdenv.hostPlatform.isLinux {
            inherit (config.khanelinix.theme.gtk.cursor) name package size;
          };

          sessionVariables = mkIf pkgs.stdenv.hostPlatform.isLinux {
            CURSOR_THEME = config.khanelinix.theme.gtk.cursor.name;
          };
        };

        programs = {
          # Additional program settings that don't follow the common pattern
          satty.settings = mkIf config.khanelinix.programs.graphical.addons.satty.enable {
            color-palette = {
              palette = [
                palette.colors.red.hex
                palette.colors.peach.hex
                palette.colors.yellow.hex
                palette.colors.green.hex
                palette.colors.teal.hex
                palette.colors.blue.hex
                palette.colors.mauve.hex
                palette.colors.pink.hex
              ];

              custom = [
                palette.colors.red.hex
                palette.colors.maroon.hex
                palette.colors.peach.hex
                palette.colors.yellow.hex
                palette.colors.green.hex
                palette.colors.teal.hex
                palette.colors.sky.hex
                palette.colors.sapphire.hex
                palette.colors.blue.hex
                palette.colors.lavender.hex
                palette.colors.mauve.hex
                palette.colors.pink.hex
                palette.colors.flamingo.hex
                palette.colors.rosewater.hex
              ];
            };
          };

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

          opencode.settings.theme = lib.mkForce "catppuccin";
          vicinae.settings.theme.name = lib.mkForce "catppuccin-macchiato";

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

          vesktop.vencord = {
            settings.enabledThemes = [
              "catppuccin.css"
            ];
            # TODO: use packaged version
            themes.catppuccin = ./Catppuccin-Macchiato-BD/src.css;
          };

          yazi.theme = lib.mkMerge [
            (import ./yazi/filetype.nix)
            (import ./yazi/manager.nix)
            (import ./yazi/theme.nix)
          ];
        };

        wayland.windowManager.hyprland.settings.plugin.hyprbars = {
          bar_color = palette.colors.base.rgb;

          hyprbars-button = lib.mkForce [
            # close
            "rgb(ED8796), 15, 󰅖, hyprctl dispatch killactive"
            # maximize
            "rgb(C6A0F6), 15, , hyprctl dispatch fullscreen 1"
          ];
        };

        xdg.configFile =
          mkIf (pkgs.stdenv.hostPlatform.isLinux && config.khanelinix.programs.graphical.apps.discord.enable)
            {
              # TODO: use packaged version
              "ArmCord/themes/Catppuccin-Macchiato-BD".source = ./Catppuccin-Macchiato-BD;
              "BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
            };
      }
    ]
  );
}
