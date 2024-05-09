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
            font = wezterm.font_with_fallback {
              'MonaspiceKr Nerd Font',
              'CaskaydiaCove Nerd Font',
              'Noto Color Emoji',
            },
            color_schemes = {
              ["Catppuccin"] = custom,
            },
            color_scheme = "Catppuccin",
            use_fancy_tab_bar = false,
            tab_bar_at_bottom = true,
            term = "xterm-256color",
            window_close_confirmation = 'NeverPrompt',
            window_decorations = "RESIZE",
            warn_about_missing_glyphs=false,
          }
        '';
    };
  };
}
