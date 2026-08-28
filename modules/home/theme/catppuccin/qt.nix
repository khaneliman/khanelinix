{
  config,
  lib,

  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.catppuccin;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix = {
      theme = {
        qt = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          theme = {
            name = "catppuccin-macchiato-blue";
            package = pkgs.catppuccin-kvantum.override {
              accent = "blue";
              variant = "macchiato";
            };
          };

          qml.palette = {
            AlternateBase = "#24273a";
            Base = "#1e2030";
            BrightText = "#cad3f5";
            Button = "#363a4f";
            ButtonText = "#cad3f5";
            Dark = "#181926";
            Highlight = "#8aadf4";
            HighlightedText = "#1e2030";
            Light = "#5b6078";
            Link = "#8aadf4";
            LinkVisited = "#b7bdf8";
            Mid = "#1e2030";
            Midlight = "#494d64";
            PlaceholderText = "#6e738d";
            Shadow = "#181926";
            Text = "#cad3f5";
            ToolTipBase = "#24273a";
            ToolTipText = "#cad3f5";
            Window = "#24273a";
            WindowText = "#cad3f5";
          };
        };
      };
    };
  };
}
