{
  config,
  lib,

  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.catppuccin;
  colors = config.khanelinix.theme.active;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix = {
      theme = {
        qt = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          theme = {
            name = "catppuccin-${cfg.flavor}-${cfg.accent}";
            package = pkgs.catppuccin-kvantum.override {
              inherit (cfg) accent;
              variant = cfg.flavor;
            };
          };

          qml.palette = {
            AlternateBase = colors.background;
            Base = colors.surface;
            BrightText = colors.foreground;
            Button = colors.surface;
            ButtonText = colors.foreground;
            Dark = colors.shadow;
            Highlight = colors.accent;
            HighlightedText = colors.accentForeground;
            Light = colors.border;
            Link = colors.accent;
            LinkVisited = colors.secondary;
            Mid = colors.surface;
            Midlight = colors.border;
            PlaceholderText = colors.muted;
            Shadow = colors.shadow;
            Text = colors.foreground;
            ToolTipBase = colors.background;
            ToolTipText = colors.foreground;
            Window = colors.background;
            WindowText = colors.foreground;
          };
        };
      };
    };
  };
}
