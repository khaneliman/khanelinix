{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs) tokyonight;
  inherit (lib) mkIf mkForce;

  cfg = config.khanelinix.theme.tokyonight;
  variant = if cfg.variant == "storm" then "night" else cfg.variant;
  colors = (import ./colors.nix).getVariant cfg.variant;
in
{
  config = mkIf cfg.enable {
    programs = {
      #          ╭──────────────────────────────────────────────────────────╮
      #          │   Available application configurations from tokyonight   │
      #          │                         extras:                          │
      #          │   aerc, aider, alacritty, btop, delta, discord, dunst,   │
      #          │              eza, fish, fish_themes, foot,               │
      #          │   fuzzel, fzf, ghostty, gitui, gnome_terminal, helix,    │
      #          │           ish, iterm, kitty, konsole, lazygit,           │
      #          │    lua, opencode, prism, process_compose, qterminal,     │
      #          │           slack, spotify_player, st, sublime,            │
      #          │    tailwindv4, terminator, termux, tilix, tmux, vim,     │
      #          │  vimium, vivaldi, wezterm, windows_terminal, xfceterm,   │
      #          │            xresources, yazi, zathura, zellij             │
      #          ╰──────────────────────────────────────────────────────────╯

      alacritty.settings.general.import = [
        "${tokyonight}/extras/alacritty/tokyonight_${variant}.toml"
      ];

      bat.config.theme = "tokyonight_${variant}";

      btop.settings.color_theme = mkForce "tokyonight_${variant}";

      delta.options = mkIf config.programs.delta.enable (
        let
          deltaConfig = builtins.readFile "${tokyonight}/extras/delta/tokyonight_${variant}.gitconfig";
          lines = lib.splitString "\n" deltaConfig;
          # Parse the gitconfig into an attrset
          parseLine =
            line:
            let
              trimmed = lib.trim line;
              # Skip empty lines, comments, and [delta] section header
              isValid = trimmed != "" && !(lib.hasPrefix "#" trimmed) && !(lib.hasPrefix "[" trimmed);
            in
            if isValid then
              let
                parts = lib.splitString "=" trimmed;
                key = lib.trim (builtins.head parts);
                value = lib.trim (lib.concatStringsSep "=" (lib.tail parts));
              in
              lib.nameValuePair key value
            else
              null;
          parsed = builtins.filter (x: x != null) (map parseLine lines);
        in
        builtins.listToAttrs parsed
      );

      fish.interactiveShellInit = ''
        source ${tokyonight}/extras/fish/tokyonight_${variant}.fish
      '';

      foot.settings.colors = /* toml */ ''
        ${builtins.readFile "${tokyonight}/extras/foot/tokyonight_${variant}.ini"}
      '';

      fzf.defaultOptions = [
        "--color=fg:${colors.fg}"
        "--color=bg:${colors.bg}"
        "--color=hl:${colors.blue}"
        "--color=fg+:${colors.fg}"
        "--color=bg+:${colors.bg_highlight}"
        "--color=hl+:${colors.blue}"
        "--color=info:${colors.cyan}"
        "--color=prompt:${colors.blue}"
        "--color=pointer:${colors.cyan}"
        "--color=marker:${colors.cyan}"
        "--color=spinner:${colors.cyan}"
        "--color=header:${colors.blue}"
      ];

      gh-dash.settings.theme.selected_line = mkForce "bg:default fg:white bold";

      helix.settings.theme = "tokyonight_${variant}";

      kitty.extraConfig = ''
        include ${tokyonight}/extras/kitty/tokyonight_${variant}.conf
      '';

      lazygit.settings.gui.theme = {
        lightTheme = cfg.variant == "day";
        activeBorderColor = [
          "blue"
          "bold"
        ];
        inactiveBorderColor = [ "white" ];
        selectedLineBgColor = [ "blue" ];
      };

      ncspot.settings = {
        theme = {
          background = colors.bg;
          primary = colors.fg;
          secondary = colors.bg_dark;
          title = colors.blue;
          playing = colors.blue;
          playing_selected = colors.cyan;
          playing_bg = colors.bg_dark1;
          highlight = colors.magenta;
          highlight_bg = colors.bg_highlight;
          error = colors.fg;
          error_bg = colors.red;
          statusbar = colors.bg_dark1;
          statusbar_progress = colors.fg;
          statusbar_bg = colors.blue;
          cmdline = colors.fg;
          cmdline_bg = colors.bg_dark1;
          search_match = colors.purple;
        };
      };

      opencode.settings.theme = lib.mkForce "tokyonight";

      satty.settings = mkIf config.khanelinix.programs.graphical.addons.satty.enable {
        color-palette = {
          palette = [
            colors.red
            colors.orange
            colors.yellow
            colors.green
            colors.teal
            colors.blue
            colors.magenta
            colors.purple
          ];

          custom = [
            colors.red
            colors.red1
            colors.orange
            colors.yellow
            colors.green
            colors.green1
            colors.green2
            colors.teal
            colors.cyan
            colors.blue
            colors.blue1
            colors.blue2
            colors.magenta
            colors.purple
          ];
        };
      };

      tmux.extraConfig = ''
        source-file ${tokyonight}/extras/tmux/tokyonight_${variant}.tmux
      '';

      vicinae.settings.theme.name = lib.mkForce "tokyo-night";

      vesktop.vencord = mkIf config.khanelinix.programs.graphical.apps.discord.enable {
        settings.enabledThemes = [ "tokyonight.css" ];
        themes.tokyonight = "${tokyonight}/extras/discord/tokyonight_${cfg.variant}.css";
      };

      wezterm.extraConfig = ''
        config.color_scheme = "tokyonight_${variant}"
      '';

      zellij.settings.theme = "tokyonight_${variant}";
    };

    xdg.configFile = lib.mkMerge [
      (mkIf config.programs.bat.enable {
        "bat/themes/tokyonight_${variant}.tmTheme".source =
          "${tokyonight}/extras/sublime/tokyonight_${variant}.tmTheme";
      })

      (mkIf config.programs.btop.enable {
        "btop/themes/tokyonight_${variant}.theme".source =
          "${tokyonight}/extras/btop/tokyonight_${variant}.theme";
      })

      (mkIf config.services.dunst.enable {
        "dunst/tokyonight_${variant}.conf".source = "${tokyonight}/extras/dunst/tokyonight_${variant}.conf";
      })

      (mkIf config.programs.eza.enable {
        "eza/theme.yml".source = mkForce "${tokyonight}/extras/eza/tokyonight_${variant}.yml";
      })

      (mkIf config.programs.fuzzel.enable {
        "fuzzel/tokyonight.ini".source = "${tokyonight}/extras/fuzzel/tokyonight_${variant}.ini";
      })

      (mkIf config.programs.ghostty.enable {
        "ghostty/themes/tokyonight_${variant}".source =
          "${tokyonight}/extras/ghostty/tokyonight_${variant}";
      })

      (mkIf config.programs.gitui.enable {
        "gitui/theme.ron".source = mkForce "${tokyonight}/extras/gitui/tokyonight_${variant}.ron";
      })

      (mkIf config.programs.yazi.enable {
        "yazi/theme.toml".source = mkForce (
          pkgs.runCommand "tokyonight-yazi-theme.toml" { } ''
            sed 's/name =/url =/g' ${tokyonight}/extras/yazi/tokyonight_${variant}.toml > $out
          ''
        );
      })

      (mkIf config.programs.zathura.enable {
        "zathura/tokyonight".source = "${tokyonight}/extras/zathura/tokyonight_${variant}.zathurarc";
      })

      (mkIf config.programs.zellij.enable {
        "zellij/themes/tokyonight.kdl".source = "${tokyonight}/extras/zellij/tokyonight_${variant}.kdl";
      })

      (mkIf config.programs.wezterm.enable {
        "wezterm/colors/tokyonight_${variant}.toml".source =
          "${tokyonight}/extras/wezterm/tokyonight_${variant}.toml";
      })

      (mkIf config.programs.cava.enable {
        "cava/config".text = ''
          [color]
          gradient = 1
          gradient_count = 6
          gradient_color_1 = '${colors.blue}'
          gradient_color_2 = '${colors.cyan}'
          gradient_color_3 = '${colors.green}'
          gradient_color_4 = '${colors.yellow}'
          gradient_color_5 = '${colors.orange}'
          gradient_color_6 = '${colors.red}'
        '';
      })

      (mkIf config.programs.fish.enable {
        "fish/themes/tokyonight_${variant}.theme".source =
          "${tokyonight}/extras/fish_themes/tokyonight_${variant}.theme";
      })

      (mkIf config.khanelinix.programs.terminal.tools.opencode.enable {
        "opencode/themes/tokyonight.json".source =
          "${tokyonight}/extras/opencode/tokyonight_${variant}.json";
      })

      (mkIf config.khanelinix.programs.graphical.bars.sketchybar.enable {
        "sketchybar/colors.lua".text =
          let
            toLuaColor = hex: "0xff" + builtins.substring 1 6 hex;
          in
          ''
            #!/usr/bin/env lua

            local colors = {
              base = ${toLuaColor colors.bg},
              mantle = ${toLuaColor colors.bg_dark},
              crust = ${toLuaColor colors.bg_dark1},
              text = ${toLuaColor colors.fg},
              subtext0 = ${toLuaColor colors.fg_dark},
              subtext1 = ${toLuaColor colors.dark5},
              surface0 = ${toLuaColor colors.bg_highlight},
              surface1 = ${toLuaColor colors.terminal_black},
              surface2 = ${toLuaColor colors.dark3},
              overlay0 = ${toLuaColor colors.comment},
              overlay1 = ${toLuaColor colors.fg_gutter},
              overlay2 = ${toLuaColor colors.blue7},
              blue = ${toLuaColor colors.blue},
              lavender = ${toLuaColor colors.blue1},
              sapphire = ${toLuaColor colors.blue2},
              sky = ${toLuaColor colors.cyan},
              teal = ${toLuaColor colors.teal},
              green = ${toLuaColor colors.green},
              yellow = ${toLuaColor colors.yellow},
              peach = ${toLuaColor colors.orange},
              maroon = ${toLuaColor colors.red1},
              red = ${toLuaColor colors.red},
              mauve = ${toLuaColor colors.purple},
              pink = ${toLuaColor colors.magenta},
              flamingo = ${toLuaColor colors.magenta2},
              rosewater = ${toLuaColor colors.fg_dark},
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

      (mkIf config.khanelinix.programs.graphical.apps.discord.enable {
        "BetterDiscord/themes/tokyonight.theme.css".source =
          "${tokyonight}/extras/discord/tokyonight_${variant}.css";
        "ArmCord/themes/tokyonight.theme.css".source =
          "${tokyonight}/extras/discord/tokyonight_${variant}.css";
      })
    ];

    wayland.windowManager.hyprland.settings.plugin.hyprbars =
      let
        hexToRgb =
          hex:
          let
            r = builtins.substring 1 2 hex;
            g = builtins.substring 3 2 hex;
            b = builtins.substring 5 2 hex;
          in
          "rgb(${r}${g}${b})";
      in
      {
        bar_color = hexToRgb colors.bg;

        hyprbars-button = lib.mkForce [
          # close
          "${hexToRgb colors.red}, 15, 󰅖, hyprctl dispatch killactive"
          # maximize
          "${hexToRgb colors.magenta}, 15, , hyprctl dispatch fullscreen 1"
        ];
      };

    home.file = mkIf pkgs.stdenv.hostPlatform.isLinux {
      ".Xresources.d/tokyonight".source =
        "${tokyonight}/extras/xresources/tokyonight_${variant}.Xresources";
    };
  };
}
