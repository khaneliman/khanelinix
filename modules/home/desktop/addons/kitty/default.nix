{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.desktop.addons.kitty;
in
{
  options.khanelinix.desktop.addons.kitty = with types; {
    enable = mkBoolOpt false "Whether to enable kitty.";
    font = mkOpt str "Liga SFMono Nerd Font" "Font to use for kitty.";
    theme = mkOpt str "Catppuccin-Macchiato" "Theme to use for kitty.";
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      inherit (cfg) theme;

      settings =
        {
          # Fonts
          font_family = cfg.font;
          italic_font = "auto";
          bold_font = "auto";
          bold_italic_font = "auto";
          font_size = 12;

          adjust_line_height = 0;
          adjust_column_width = 0;
          box_drawing_scale = "0.001, 1, 1.5, 2";

          # Cursor
          cursor_shape = "underline";
          cursor_blink_interval = -1;
          cursor_stop_blinking_after = "15.0";

          # Scrollback
          scrollback_lines = 10000;
          scrollback_pager = "less";
          wheel_scroll_multiplier = "5.0";

          # URLs
          url_style = "double";
          open_url_modifiers = "ctrl + shift";
          open_url_with = "default";
          copy_on_select = "yes";

          # Selection
          rectangle_select_modifiers = "ctrl + shift";
          select_by_word_characters = ":@-./_~?& = %+#";

          # Mouse
          click_interval = "0.5";
          mouse_hide_wait = 0;
          focus_follows_mouse = "no";

          # Performance
          repaint_delay = 20;
          input_delay = 2;
          sync_to_monitor = "no";

          # Bell
          visual_bell_duration = "0.0";
          enable_audio_bell = "yes";
          bell_on_tab = "yes";

          # Window
          remember_window_size = "no";
          initial_window_width = 700;
          initial_window_height = 400;
          window_border_width = 0;
          window_margin_width = 12;
          window_padding_width = 10;
          inactive_text_alpha = "1.0";
          background_opacity = "0.90";
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
          tab_separator = " ┇ ";
          tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
          active_tab_font_style = "bold";
          inactive_tab_font_style = "normal";

          # Shell
          shell = ".";
          close_on_child_death = "no";
          allow_remote_control = "yes";
          term = "xterm-kitty";
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          hide_window_decorations = "titlebar-only";
          macos_option_as_alt = "both";
          macos_custom_beam_cursor = "yes";
          macos_thicken_font = 0;
          macos_colorspace = "displayp3";
        };

      keybindings =
        {
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
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          "cmd+opt+s" = "noop";
        };
    };
  };
}
