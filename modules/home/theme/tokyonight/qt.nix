{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.tokyonight;
  colors = (import ./colors.nix).getVariant cfg.variant;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.theme.qt = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      theme = {
        # Tokyonight does not ship a Kvantum theme in nixpkgs, so use the
        # Catppuccin Kvantum theme as the Qt fallback.
        name = "catppuccin-macchiato-blue";
        package = pkgs.catppuccin-kvantum.override {
          accent = "blue";
          variant = "macchiato";
        };
      };

      qml.palette = {
        AlternateBase = colors.bg_highlight;
        Base = colors.bg_dark;
        BrightText = colors.fg;
        Button = colors.bg_highlight;
        ButtonText = colors.fg;
        Dark = colors.bg_dark1;
        Highlight = colors.blue;
        HighlightedText = if cfg.variant == "day" then "#ffffff" else colors.bg_dark1;
        Light = colors.dark3;
        Link = colors.blue;
        LinkVisited = colors.purple;
        Mid = colors.bg_dark;
        Midlight = colors.bg_highlight;
        PlaceholderText = colors.comment;
        Shadow = colors.bg_dark1;
        Text = colors.fg;
        ToolTipBase = colors.bg_dark;
        ToolTipText = colors.fg;
        Window = colors.bg;
        WindowText = colors.fg;
      };
    };
  };
}
