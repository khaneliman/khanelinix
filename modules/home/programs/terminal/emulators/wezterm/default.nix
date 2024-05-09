{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.emulators.wezterm;
in
{
  options.khanelinix.programs.terminal.emulators.wezterm = {
    enable = mkBoolOpt false "Whether or not to enable wezterm.";
  };

  config = mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      package = pkgs.wezterm;

      extraConfig = # lua
        ''
          function scheme_for_appearance(appearance)
            if appearance:find "Dark" then
              return "Catppuccin Macchiato"
            else
              return "Catppuccin Frappe"
            end
          end

          local custom = wezterm.color.get_builtin_schemes()[scheme_for_appearance(wezterm.gui.get_appearance())]

          return {
            -- general
            audible_bell = "Disabled",
            check_for_updates = false,
            enable_scroll_bar = false,
            exit_behavior = "CloseOnCleanExit",
            warn_about_missing_glyphs =  false,
            term = "xterm-256color",

            -- anims
            animation_fps = 1,

            -- Color scheme
            color_schemes = {
              ["Catppuccin"] = custom,
            },
            color_scheme = "Catppuccin",

            -- Cursor
            cursor_blink_ease_in = 'Constant',
            cursor_blink_ease_out = 'Constant',
            cursor_blink_rate = 700,
            default_cursor_style = "SteadyBar",

            -- font
            font = wezterm.font_with_fallback {
              'MonaspiceKr Nerd Font',
              'CaskaydiaCove Nerd Font',
              'Noto Color Emoji',
            },

            -- Tab bar
            enable_tab_bar = true,
            hide_tab_bar_if_only_one_tab = true,
            show_tab_index_in_tab_bar = false,
            tab_bar_at_bottom = true,
            use_fancy_tab_bar = false,

            -- perf
            enable_wayland = true,
            front_end = "WebGpu",
            scrollback_lines = 10000,

            -- term window settings
            adjust_window_size_when_changing_font_size = false,
            inactive_pane_hsb = {
              saturation = 1.0,
              brightness = 0.8
            },
            window_background_opacity = 0.85,
            window_close_confirmation = "NeverPrompt",
            window_decorations = "RESIZE",
            window_padding = { left = 12, right = 12, top = 12, bottom = 12, },
          }
        '';
    };
  };
}
