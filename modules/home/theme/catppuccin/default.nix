{
  config,
  lib,
  options,
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

  inherit (lib.khanelinix) disabled enabled;
  inherit (inputs) yazi-flavors;

  cfg = config.khanelinix.theme.catppuccin;

  colors = (lib.importJSON "${config.catppuccin.sources.palette}/palette.json").${cfg.flavor}.colors;
  isLatte = cfg.flavor == "latte";
  # Frappe and Latte accents miss 4.5:1 on their own base, mantle, crust, and
  # surface0. These keep each color's OKLCH hue and chroma with lightness
  # solved to 4.6:1 against those surfaces, as T3 Code does for generated
  # themes; overlay2 only draws icons, so it is solved to 3.1:1. Mocha and
  # Macchiato already clear both.
  readableAccents =
    {
      frappe = {
        blue = "#97b5fa";
        mauve = "#d0a4ed";
        maroon = "#f19fa2";
        peach = "#f2a279";
        red = "#ff999b";
        subtext0 = "#adb5d6";
      };
      latte = {
        blue = "#0049d7";
        flamingo = "#96393d";
        green = "#006700";
        lavender = "#3f4aba";
        maroon = "#b2002a";
        mauve = "#761ad8";
        overlay2 = "#6d7084";
        peach = "#b10a00";
        pink = "#97277e";
        red = "#b30020";
        rosewater = "#8b4132";
        sapphire = "#006074";
        sky = "#005b96";
        subtext0 = "#54576c";
        subtext1 = "#52556d";
        teal = "#006269";
        yellow = "#8d4200";
      };
    }
    .${cfg.flavor} or { };
  readableColors = lib.mapAttrs (_: color: color.hex) colors // readableAccents;
  # Surfaces sit one step darker than Catppuccin's surface0/surface1 so muted
  # and status text clear 4.5:1; Latte inverts the ramp for a light canvas.
  t3codeTheme = import ../t3code.nix {
    inherit config lib pkgs;
    appearance = if isLatte then "light" else "dark";
    id = "khanelinix-catppuccin-${cfg.flavor}";
    name = "Catppuccin ${lib.khanelinix.capitalize cfg.flavor}";
    accent = readableColors.${cfg.accent};
    accentForeground = if isLatte then "#ffffff" else readableColors.base;
    border = readableColors.surface2;
    canvas = readableColors.base;
    chrome = readableColors.mantle;
    error = readableColors.red;
    highlight = readableColors.surface2;
    secondary = readableColors.teal;
    statusForeground = if isLatte then "#ffffff" else readableColors.crust;
    success = readableColors.green;
    surface = readableColors.mantle;
    surfaceOverlay = if isLatte then readableColors.base else readableColors.mantle;
    surfaceRaised = if isLatte then readableColors.crust else readableColors.surface0;
    inherit (readableColors) text;
    textMuted = readableColors.subtext1;
    warning = readableColors.yellow;
  };
  fzfColors = {
    "bg+" = colors.surface0.hex;
    bg = colors.base.hex;
    border = colors.overlay0.hex;
    fg = colors.text.hex;
    "fg+" = colors.text.hex;
    header = colors.${cfg.accent}.hex;
    hl = colors.${cfg.accent}.hex;
    "hl+" = colors.${cfg.accent}.hex;
    info = colors.${cfg.accent}.hex;
    label = colors.text.hex;
    marker = colors.${cfg.accent}.hex;
    pointer = colors.${cfg.accent}.hex;
    prompt = colors.${cfg.accent}.hex;
    selected-bg = colors.surface1.hex;
    spinner = colors.rosewater.hex;
  };
  ghDashTheme = {
    theme.colors = {
      background.selected = colors.surface0.hex;
      border = {
        faint = colors.surface0.hex;
        primary = colors.${cfg.accent}.hex;
        secondary = colors.surface1.hex;
      };
      text = {
        error = colors.red.hex;
        faint = colors.subtext1.hex;
        inverted = colors.crust.hex;
        primary = colors.text.hex;
        secondary = colors.${cfg.accent}.hex;
        success = colors.green.hex;
        warning = colors.yellow.hex;
      };
    };
  };

  inherit (pkgs.stdenv.hostPlatform) isLinux;
  flavorName = lib.toSentenceCase cfg.flavor;
  opencodeThemeName = "catppuccin-${cfg.flavor}-${cfg.accent}";
  opencodeThemes = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "opencode";
    rev = "d5f409632e6294762925fae869ad0c96dc17cd8e";
    hash = "sha256-7kd9M8Sr+e8WpC5gDGJStpO3RNsIx+Br5niKd7Oa5xc=";
  };
  discordThemeName = "catppuccin-${cfg.flavor}.theme.css";
  discordThemes = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "discord";
    rev = "b5c7e717b6565df60aae515390ed52d60f3ac370";
    hash = "sha256-wy3VEDeSwfsKBfxCr0wzHLqkApLZ0M1IQhMzaNpulx8=";
  };
  discordTheme =
    if cfg.flavor == "macchiato" then
      ./catppuccin-macchiato.theme.css
    else
      "${discordThemes}/dist/${discordThemeName}";
  armcordTheme =
    if cfg.flavor == "macchiato" then
      ./Catppuccin-Macchiato-BD
    else
      let
        manifest = pkgs.writeText "catppuccin-armcord-manifest.json" (
          builtins.toJSON (
            lib.importJSON ./Catppuccin-Macchiato-BD/manifest.json
            // {
              name = "Catppuccin ${flavorName}";
              updateSrc = "https://catppuccin.github.io/discord/dist/${discordThemeName}";
            }
          )
        );
      in
      pkgs.runCommand "catppuccin-${cfg.flavor}-armcord-theme" { } ''
        mkdir -p "$out"
        cp ${manifest} "$out/manifest.json"
        cp ${discordTheme} "$out/src.css"
      '';
in
{
  imports = [
    ./gtk.nix
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
      description = "Catppuccin package configured with the selected accent and flavor.";
    };
  };

  config = lib.mkMerge [
    # catppuccin/nix migration: `enable` is becoming a global on/off toggle and
    # `autoEnable` the "enroll every port" switch. Pin both explicitly so behavior
    # stays stable and the deprecation warning is silenced on every profile,
    # including hosts not using the catppuccin theme. We never auto-enroll; the
    # ports below are cherry-picked when the theme is active.
    (lib.optionalAttrs (inputs ? catppuccin && inputs.catppuccin ? homeModules) {
      catppuccin = {
        inherit (cfg) enable;
        autoEnable = false;
      };
    })

    (mkIf cfg.enable (
      lib.mkMerge [
        # Hand the selected wallpaper to stylix as nord and tokyonight do.
        (lib.optionalAttrs (options ? stylix) {
          stylix.image = lib.khanelinix.theme.wallpaperPath {
            inherit config pkgs;
            name = config.khanelinix.theme.wallpaper.primary;
          };
        })

        {
          home.activation.t3codeTheme = t3codeTheme;

          assertions = [
            {
              assertion = !config.khanelinix.theme.nord.enable;
              message = "Nord and Catppuccin themes cannot be enabled at the same time";
            }
          ];

          khanelinix = {
            theme = {
              stylix.theme = mkDefault "catppuccin-${cfg.flavor}";
              active = {
                accent = readableColors.${cfg.accent};
                accentForeground = if isLatte then "#ffffff" else readableColors.base;
                background = readableColors.base;
                border = readableColors.surface1;
                danger = readableColors.red;
                foreground = readableColors.text;
                muted = readableColors.subtext0;
                secondary = readableColors.teal;
                shadow = readableColors.crust;
                success = readableColors.green;
                surface = if isLatte then readableColors.crust else readableColors.mantle;
                warning = readableColors.yellow;
              };
              wallpaper = {
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
            };
            programs = {
              graphical = {
                apps.thunderbird.theme = {
                  enable = true;
                  isDark = !isLatte;
                  colors = {
                    bg = colors.base.hex;
                    surface = colors.surface0.hex;
                    surfaceAlt = colors.mantle.hex;
                    fg = colors.text.hex;
                    accent = readableColors.${cfg.accent};
                    accentSoft = readableColors.${cfg.accent};
                    accentFg = config.khanelinix.theme.active.accentForeground;
                    border = colors.overlay0.hex;
                  };
                };
                browsers = {
                  firefox.extensions.extraPackages =
                    mkIf config.khanelinix.programs.graphical.browsers.firefox.enable
                      [ pkgs.firefox-addons.firefox-color ];
                };
              };
            };
          };

          programs = {
            thunderbird.profiles.${config.khanelinix.user.name}.settings."extensions.autoDisableScopes" =
              mkIf config.khanelinix.programs.graphical.apps.thunderbird.enable 0;

            codex.settings.desktop =
              let
                appearance = if isLatte then "Light" else "Dark";
                inherit (config.khanelinix.theme) active;
              in
              {
                appearanceTheme = lib.toLower appearance;
                "appearance${appearance}CodeThemeId" = "catppuccin-${cfg.flavor}";
                "appearance${appearance}ChromeTheme" = {
                  surface = active.background;
                  ink = active.foreground;
                  inherit (active) accent;
                  contrast = 45;
                  fonts = { };
                  opaqueWindows = false;
                  semanticColors = {
                    diffAdded = active.success;
                    diffRemoved = active.danger;
                    skill = active.accent;
                  };
                };
              };
          };
        }
        (lib.optionalAttrs (inputs ? catppuccin && inputs.catppuccin ? homeModules) {
          catppuccin = {
            # enable + autoEnable are pinned unconditionally above; here we only
            # cherry-pick the ports that should receive catppuccin styling.
            inherit (cfg) accent flavor;

            # keep-sorted start block=yes
            alacritty = enabled;
            atuin = enabled;
            bat = enabled;
            bottom = enabled;
            btop = enabled;
            cava = enabled;
            delta = enabled;
            firefox.profiles.${config.khanelinix.user.name} = {
              enable = config.khanelinix.programs.graphical.browsers.firefox.enable;
              force = true;
            };
            fish = enabled;
            # Static local settings avoid upstream generated palette imports during eval.
            fzf = disabled;
            # Static local settings avoid upstream generated YAML conversion during eval.
            gh-dash = disabled;
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
            nushell = enabled;
            television = enabled;
            thunderbird = {
              enable = true;
              profile = config.khanelinix.user.name;
            };
            tmux = enabled;
            # NOTE: uses remote url import
            # I already have a local file
            # vesktop = enabled;
            zathura = enabled;
            zellij = enabled;
            zsh-syntax-highlighting = enabled;
            # keep-sorted end
          }
          // lib.optionalAttrs isLinux {
            foot = enabled;
            hyprland = mkIf config.khanelinix.programs.graphical.wms.hyprland.enable {
              enable = true;
              inherit (cfg) accent;
            };
            sway = enabled;
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

                  warpStyle = "${warpPkg.outPath}/themes/catppuccin_${cfg.flavor}.yml";
                in
                mkIf config.khanelinix.programs.terminal.emulators.warp.enable {
                  ".warp/themes/catppuccin_${cfg.flavor}.yaml".source = warpStyle;
                  ".local/share/warp-terminal/themes/catppuccin_${cfg.flavor}.yaml".source = warpStyle;
                }
              )
              (mkIf pkgs.stdenv.hostPlatform.isDarwin {
                "Library/Application Support/BetterDiscord/themes/${discordThemeName}".source = discordTheme;
              })
            ];

            pointerCursor = mkIf pkgs.stdenv.hostPlatform.isLinux {
              enable = true;
              inherit (config.khanelinix.theme.gtk.cursor) name package size;
            };

            sessionVariables = mkIf pkgs.stdenv.hostPlatform.isLinux {
              CURSOR_THEME = config.khanelinix.theme.gtk.cursor.name;
            };
          };

          programs = {
            # Additional program settings that don't follow the common pattern
            # Codex bundles the catppuccin syntax themes upstream.
            codex.settings.tui.theme = "catppuccin-${cfg.flavor}";

            oh-my-posh.settings.palette = import ./oh-my-posh.nix { inherit colors; };

            fzf.colors = mkIf config.khanelinix.programs.terminal.tools.fzf.enable fzfColors;

            gh-dash.settings = mkIf config.khanelinix.programs.terminal.tools.gh.enable ghDashTheme;

            ghostty.settings = mkIf pkgs.stdenv.hostPlatform.isDarwin {
              macos-icon = "custom-style";
              macos-icon-ghost-color = colors.${cfg.accent}.hex;
              macos-icon-screen-color = "${colors.surface0.hex},${colors.base.hex}";
            };

            satty.settings = mkIf config.khanelinix.programs.graphical.addons.satty.enable {
              color-palette = {
                palette = [
                  colors.red.hex
                  colors.peach.hex
                  colors.yellow.hex
                  colors.green.hex
                  colors.teal.hex
                  colors.blue.hex
                  colors.mauve.hex
                  colors.pink.hex
                ];

                custom = [
                  colors.red.hex
                  colors.maroon.hex
                  colors.peach.hex
                  colors.yellow.hex
                  colors.green.hex
                  colors.teal.hex
                  colors.sky.hex
                  colors.sapphire.hex
                  colors.blue.hex
                  colors.lavender.hex
                  colors.mauve.hex
                  colors.pink.hex
                  colors.flamingo.hex
                  colors.rosewater.hex
                ];
              };
            };

            ncspot.settings.theme = {
              background = colors.base.hex;
              primary = colors.text.hex;
              secondary = colors.mantle.hex;
              title = readableColors.${cfg.accent};
              playing = readableColors.${cfg.accent};
              playing_selected = readableColors.lavender;
              playing_bg = colors.crust.hex;
              highlight = readableColors.mauve;
              highlight_bg = colors.surface1.hex;
              error = config.khanelinix.theme.active.accentForeground;
              error_bg = readableColors.red;
              statusbar = config.khanelinix.theme.active.accentForeground;
              statusbar_progress = colors.text.hex;
              statusbar_bg = readableColors.${cfg.accent};
              cmdline = colors.text.hex;
              cmdline_bg = colors.crust.hex;
              search_match = readableColors.pink;
            };

            opencode.tui.theme = lib.mkForce opencodeThemeName;
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
              themes.catppuccin =
                if cfg.flavor == "macchiato" then ./Catppuccin-Macchiato-BD/src.css else discordTheme;
            };

            wezterm.extraConfig = lib.mkBefore /* Lua */ ''
              function scheme_for_appearance()
                return "Catppuccin ${flavorName}"
              end
            '';

            yazi = {
              flavors.${cfg.flavor} = "${yazi-flavors}/catppuccin-${cfg.flavor}.yazi";
              theme = lib.mkForce (
                {
                  flavor = {
                    dark = cfg.flavor;
                    light = cfg.flavor;
                  };
                }
                // (import ./yazi/filetype.nix { inherit colors; })
                // (import ./yazi/manager.nix { inherit colors; })
                // (import ./yazi/theme.nix { inherit colors; })
              );
            };
          };

          xdg.configFile = mkMerge [
            (mkIf (isLinux && config.khanelinix.programs.graphical.apps.discord.enable) {
              "ArmCord/themes/Catppuccin-${flavorName}-BD".source = armcordTheme;
              "BetterDiscord/themes/${discordThemeName}".source = discordTheme;
            })
            (mkIf config.khanelinix.programs.terminal.tools.opencode.enable {
              "opencode/themes/${opencodeThemeName}.json".source =
                "${opencodeThemes}/themes/${cfg.flavor}/${opencodeThemeName}.json";
            })
          ];
        }
      ]
    ))
  ];
}
