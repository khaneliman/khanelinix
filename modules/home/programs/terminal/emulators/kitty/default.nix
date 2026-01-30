{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.terminal.emulators.kitty;
  fontCfg = config.khanelinix.fonts;

  monaspaceArgon = fontCfg.monaspace.families.argon;
  monaspaceKrypton = fontCfg.monaspace.families.krypton;
  monaspaceNeon = fontCfg.monaspace.families.neon;
  monaspaceRadon = fontCfg.monaspace.families.radon;
  monaspaceXenon = fontCfg.monaspace.families.xenon;

  removeSpaces = builtins.replaceStrings [ " " ] [ "" ];
in
{
  options.khanelinix.programs.terminal.emulators.kitty = with types; {
    enable = lib.mkEnableOption "kitty";
    font = {
      normal = mkOpt str monaspaceNeon "Font to use for kitty.";
      bold = mkOpt str monaspaceXenon "Font to use for kitty.";
      italic = mkOpt str monaspaceRadon "Font to use for kitty.";
      bold_italic = mkOpt str monaspaceKrypton "Font to use for kitty.";
    };
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      # Shared clipboard that works over ssh
      clipboard = "kitten clipboard";
      # Pretty diff
      diff = "kitten diff";
      # QOL alias for copying terminfo
      ssh = "kitten ssh";
      # cat for images
      icat = "kitten icat";
    };

    xdg.configFile."kitty/nix.conf".text = /* Bash */ ''
      launch zellij

      new_tab khanelivim
      cd ${config.home.homeDirectory}/github/khanelivim
      launch zellij --layout dev  attach --create "$(basename "$(pwd)")" options --default-cwd "$(pwd)"

      new_tab nixvim
      cd ${config.home.homeDirectory}/github/nixvim
      launch zellij --layout dev  attach --create "$(basename "$(pwd)")" options --default-cwd "$(pwd)"

      new_tab home-manager
      cd ${config.home.homeDirectory}/github/home-manager
      launch zellij --layout dev  attach --create "$(basename "$(pwd)")" options --default-cwd "$(pwd)"

      new_tab nixpkgs
      cd ${config.home.homeDirectory}/github/nixpkgs
      launch zellij --layout dev  attach --create "$(basename "$(pwd)")" options --default-cwd "$(pwd)"
    '';

    programs = {
      kitty = {
        enable = true;
        enableGitIntegration = true;

        darwinLaunchOptions = [
          "--single-instance"
          "--listen-on=unix:/tmp/kitty.sock"
        ];

        extraConfig =
          let
            fontFeatures = ffs: builtins.concatStringsSep "\n" (map (ff: "font_features ${ff}") ffs);

            # TODO: move to font specific module
            monaspaceFontFeatures = "+calt +liga +dlig +ss01 +ss02 +ss03 +ss04 +ss05 +ss06 +ss07 +ss08 +ss09 +ss10";
            monaspaceStyles = [
              "Bold"
              "BoldItalic"
              "ExtraBold"
              "ExtraBoldItalic"
              "ExtraLightItalic"
              "Italic"
              "Light"
              "LightItalic"
              "Medium"
              "MediumItalic"
              "Regular"
              "SemiBold"
              "SemiBoldItalic"
              "SemiWideBold"
              "SemiWideBoldItalic"
              "SemiWideExtraBold"
              "SemiWideExtraBoldItalic"
              "SemiWideExtraLight"
              "SemiWideExtraLightItalic"
              "SemiWideItalic"
              "SemiWideLight"
              "SemiWideLightItalic"
              "SemiWideMedium"
              "SemiWideMediumItalic"
              "SemiWideRegular"
              "SemiWideSemiBold"
              "SemiWideSemiBoldItalic"
              "WideBold"
              "WideBoldItalic"
              "WideExtraBold"
              "WideExtraBoldItalic"
              "WideExtraLight"
              "WideExtraLightItalic"
              "WideItalic"
              "WideLight"
              "WideLightItalic"
              "WideMedium"
              "WideMediumItalic"
              "WideRegular"
              "WideSemiBold"
              "WideSemiBoldItalic"
            ];
          in
          builtins.concatStringsSep "\n" (
            [
              (fontFeatures (
                builtins.concatLists (
                  map (font: map (style: "${font}-${style} ${monaspaceFontFeatures}") monaspaceStyles) [
                    (removeSpaces monaspaceArgon)
                    (removeSpaces monaspaceKrypton)
                    (removeSpaces monaspaceNeon)
                    (removeSpaces monaspaceRadon)
                    (removeSpaces monaspaceXenon)
                  ]
                )
              ))
            ]
            # Emoji font
            ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              "symbol_map U+1F600-U+1F64F Noto Color Emoji"
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
            ]
          );

        keybindings = {
          "ctrl+shift+v" = "paste_from_clipboard";
          "ctrl+shift+s" = "paste_from_selection";
          "ctrl+shift+c" = "copy_to_clipboard";
          "shift+insert" = "paste_from_selection";

          "ctrl+shift+up" = "scroll_line_up";
          "ctrl+shift+down" = "scroll_line_down";
          "ctrl+shift+k" = "scroll_line_up";
          "ctrl+shift+j" = "scroll_line_down";
          "ctrl+shift+page_up" = "scroll_page_up";
          "ctrl+shift+page_down" = "scroll_page_down";
          "ctrl+shift+home" = "scroll_home";
          "ctrl+shift+end" = "scroll_end";
          "ctrl+shift+h" = "show_scrollback";

          "ctrl+shift+enter" = "new_window";
          "ctrl+shift+n" = "new_os_window";
          "ctrl+shift+w" = "close_window";
          "ctrl+shift+]" = "next_window";
          "ctrl+shift+[" = "previous_window";
          "ctrl+shift+f" = "move_window_forward";
          "ctrl+shift+b" = "move_window_backward";
          "ctrl+shift+`" = "move_window_to_top";
          "ctrl+shift+1" = "first_window";
          "ctrl+shift+2" = "second_window";
          "ctrl+shift+3" = "third_window";
          "ctrl+shift+4" = "fourth_window";
          "ctrl+shift+5" = "fifth_window";
          "ctrl+shift+6" = "sixth_window";
          "ctrl+shift+7" = "seventh_window";
          "ctrl+shift+8" = "eighth_window";
          "ctrl+shift+9" = "ninth_window";
          "ctrl+shift+0" = "tenth_window";

          "ctrl+shift+right" = "next_tab";
          "ctrl+shift+left" = "previous_tab";
          "ctrl+shift+t" = "new_tab";
          "ctrl+shift+q" = "close_tab";
          "ctrl+shift+l" = "next_layout";
          "ctrl+shift+." = "move_tab_forward";
          "ctrl+shift+," = "move_tab_backward";
          "ctrl+shift+alt+t" = "set_tab_title";

          "ctrl+shift+equal" = "increase_font_size";
          "ctrl+shift+minus" = "decrease_font_size";
          "ctrl+shift+backspace" = "restore_font_size";
          "ctrl+shift+f6" = "set_font_size 16.0";
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin { "cmd+opt+s" = "noop"; };

        settings = {
          # Fonts
          font_family = cfg.font.normal;
          italic_font = cfg.font.italic;
          bold_font = cfg.font.bold;
          bold_italic_font = cfg.font.bold_italic;
          font_size = 13;

          adjust_line_height = 0;
          adjust_column_width = 0;
          box_drawing_scale = "0.001, 1, 1.5, 2";

          # clipboard
          copy_on_select = "yes";
          strip_trailing_spaces = "always";

          # Cursor
          cursor_shape = "underline";
          cursor_blink_interval = -1;
          cursor_stop_blinking_after = "15.0";
          cursor_trail = 100;
          cursor_trail_decay = "0.1 0.4";

          # Scrollback
          scrollback_lines = 10000;
          scrollback_pager = "less";
          wheel_scroll_multiplier = "5.0";

          # URLs
          url_style = "double";
          # FIXME: removed option https://sw.kovidgoyal.net/kitty/changelog/#id41
          # open_url_modifiers = "ctrl + shift";
          open_url_with = "default";

          # Selection
          # FIXME: removed option https://sw.kovidgoyal.net/kitty/changelog/#id41
          # rectangle_select_modifiers = "ctrl + shift";
          select_by_word_characters = ":@-./_~?& = %+#";

          # Mouse
          click_interval = "0.5";
          mouse_hide_wait = -1;
          focus_follows_mouse = "no";

          # Performance
          repaint_delay = 8; # Hz = 1 / (ms / 1000)

          input_delay = 2;
          sync_to_monitor = "no";

          # Bell
          visual_bell_duration = "0.0";
          enable_audio_bell = "yes";
          bell_on_tab = "yes";

          # Notification
          notify_on_cmd_finish = "unfocused";

          # Window
          remember_window_size = "no";
          initial_window_width = 700;
          initial_window_height = 400;
          window_border_width = 0;
          window_margin_width = 0;
          window_padding_width = 0;
          inactive_text_alpha = "0.8";
          background_opacity = lib.mkDefault "0.90";
          background_blur = lib.mkDefault "20";
          dynamic_background_opacity = "yes";
          placement_strategy = "center";
          hide_window_decorations = "yes";
          confirm_os_window_close = -1;
          # 0 if you dont want confirmation to close kitty instances with running commands

          # Layouts
          enabled_layouts = "*";

          # Tabs
          tab_bar_edge = "bottom";
          tab_bar_margin_width = "0.0";
          tab_bar_min_tabs = 1;
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
          tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{index}: {title}";
          active_tab_font_style = "bold";
          inactive_tab_font_style = "normal";

          # Shell
          shell = ".";
          close_on_child_death = "no";
          allow_remote_control = "socket-only";
          term = "xterm-kitty";
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          listen_on = "unix:$\{XDG_RUNTIME_DIR}/kitty";
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          hide_window_decorations = "titlebar-only";
          macos_option_as_alt = "both";
          macos_custom_beam_cursor = "yes";
          macos_thicken_font = 0;
          macos_colorspace = "displayp3";
          macos_show_window_title_in = "none";
          # kitty expects a numeric value here (not "platform")
          text_composition_strategy = "1.0";
        };

        shellIntegration = {
          enableBashIntegration = true;
          enableFishIntegration = true;
          enableZshIntegration = true;

          mode = "no-title";
        };
      };

      # Enable hyperlinks in ripgrep results
      ripgrep.arguments = [
        "--hyperlink-format=kitty"
      ];
    };
  };
}
