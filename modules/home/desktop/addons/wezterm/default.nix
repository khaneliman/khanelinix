{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.wezterm;
in
{
  options.khanelinix.desktop.addons.wezterm = {
    enable = mkBoolOpt false "Whether or not to enable wezterm.";
  };

  config = mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      package = pkgs.wezterm;

      extraConfig = ''
        function scheme_for_appearance(appearance)
          if appearance:find "Dark" then
            return "Catppuccin Macchiato"
          else
            return "Catppuccin Frappe"
          end
        end

        local custom = wezterm.color.get_builtin_schemes()[scheme_for_appearance(wezterm.gui.get_appearance())]

        return {
          window_decorations = "RESIZE",
          font = wezterm.font_with_fallback {
            'Liga SFMono Nerd Font',
            'CaskaydiaCove Nerd Font',
            'JetBrains Mono',
          },
          color_schemes = {
            ["Catppuccin"] = custom,
          },
          color_scheme = "Catppuccin",
          use_fancy_tab_bar = false,
          tab_bar_at_bottom = true,
          term = "wezterm",
        }
      '';
    };
  };
}
