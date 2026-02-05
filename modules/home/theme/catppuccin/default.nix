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
    mkDefault
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
      {
        assertions = [
          {
            assertion = !config.khanelinix.theme.nord.enable;
            message = "Nord and Catppuccin themes cannot be enabled at the same time";
          }
        ];

        khanelinix.theme.wallpaper = {
          theme = mkDefault "catppuccin";
          primary = mkDefault "flatppuccin_macchiato.png";
          secondary = mkDefault "cat-sound.png";
          lock = mkDefault "flatppuccin_macchiato.png";
          list = mkDefault [
            "flatppuccin_macchiato.png"
            "cat_pacman.png"
            "cat-sound.png"
          ];
        };
      }
      (lib.optionalAttrs (inputs ? catppuccin && inputs.catppuccin ? homeModules) {
        catppuccin = {
          # NOTE: Need some customization and merging of configuration files so cant just enable all
          enable = false;

          accent = "blue";
          flavor = "macchiato";

          # keep-sorted start block=yes
          alacritty = enabled;
          atuin = enabled;
          bat = enabled;
          bottom = enabled;
          btop = enabled;
          cava = enabled;
          delta = enabled;
          firefox = mkIf config.khanelinix.programs.graphical.browsers.firefox.enable {
            profiles.${config.khanelinix.user.name} = {
              enable = true;
              force = true;
            };
          };
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
          nushell = enabled;
          sway = enabled;
          television = enabled;
          thunderbird = {
            enable = true;
            profile = config.khanelinix.user.name;
          };
          tmux = enabled;
          # NOTE: uses remote url import
          # I already have a local file
          # vesktop = enabled;
          vicinae.enable = pkgs.stdenv.hostPlatform.isLinux;
          waybar = enabled;
          zathura = enabled;
          zellij = enabled;
          zsh-syntax-highlighting = enabled;
          # keep-sorted end
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
          vicinae.settings.theme = lib.mkForce {
            name = "catppuccin-macchiato";
            light.name = "catppuccin-latte";
            dark.name = "catppuccin-macchiato";
          };

          tmux.plugins = [
            {
              plugin = pkgs.tmuxPlugins.catppuccin;
              extraConfig = /* Bash */ ''
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

          wezterm.extraConfig = /* Lua */ ''
            function scheme_for_appearance(appearance)
              if appearance:find "Dark" then
                return "Catppuccin Macchiato"
              else
                return "Catppuccin Frappe"
              end
            end
          '';

          yazi.theme = lib.mkForce (
            lib.mkMerge [
              (import ./yazi/filetype.nix)
              (import ./yazi/manager.nix)
              (import ./yazi/theme.nix)
            ]
          );
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

        xdg.configFile = mkMerge [
          (mkIf (pkgs.stdenv.hostPlatform.isLinux && config.khanelinix.programs.graphical.apps.discord.enable)
            {
              # TODO: use packaged version
              "ArmCord/themes/Catppuccin-Macchiato-BD".source = ./Catppuccin-Macchiato-BD;
              "BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
            }
          )

          (mkIf config.khanelinix.programs.graphical.bars.sketchybar.enable {
            "sketchybar/colors.lua".text = ''
              #!/usr/bin/env lua

              local colors = {
                base = 0xff24273a,
                mantle = 0xff1e2030,
                crust = 0xff181926,
                text = 0xffcad3f5,
                subtext0 = 0xffb8c0e0,
                subtext1 = 0xffa5adcb,
                surface0 = 0xff363a4f,
                surface1 = 0xff494d64,
                surface2 = 0xff5b6078,
                overlay0 = 0xff6e738d,
                overlay1 = 0xff8087a2,
                overlay2 = 0xff939ab7,
                blue = 0xff8aadf4,
                lavender = 0xffb7bdf8,
                sapphire = 0xff7dc4e4,
                sky = 0xff91d7e3,
                teal = 0xff8bd5ca,
                green = 0xffa6da95,
                yellow = 0xffeed49f,
                peach = 0xfff5a97f,
                maroon = 0xffee99a0,
                red = 0xffed8796,
                mauve = 0xffc6a0f6,
                pink = 0xfff5bde6,
                flamingo = 0xfff0c6c6,
                rosewater = 0xfff4dbd6,
              }

              colors.random_cat_color = {
                colors.blue,
                colors.lavender,
                colors.sapphire,
                colors.sky,
                colors.teal,
                colors.green,
                colors.yellow,
                colors.peach,
                colors.maroon,
                colors.red,
                colors.mauve,
                colors.pink,
                colors.flamingo,
                colors.rosewater,
              }

              colors.getRandomCatColor = function()
                return colors.random_cat_color[math.random(1, #colors.random_cat_color)]
              end

              return colors
            '';
          })
        ];
      }
    ]
  );
}
