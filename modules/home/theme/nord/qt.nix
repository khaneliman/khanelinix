{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.nord;

  highlightColor =
    if cfg.variant == "darker" then
      "#4c566a"
    else if cfg.variant == "bluish" then
      "#81a1c1"
    else
      "#8fbcbb";
  highlightedTextColor = if cfg.variant == "default" then "#2e3440" else "#d8dee9";
  qtThemeName =
    if cfg.variant == "darker" then
      "Nordic-Darker"
    else if cfg.variant == "bluish" then
      "Nordic-bluish"
    else
      "Nordic";
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.theme.qt = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      theme = {
        name = qtThemeName;
        package = pkgs.nordic;
      };

      qml.palette = {
        AlternateBase = "#434c5e";
        Base = "#3b4252";
        BrightText = "#eceff4";
        Button = "#3c4454";
        ButtonText = "#d8dee9";
        Dark = "#2e3440";
        Highlight = highlightColor;
        HighlightedText = highlightedTextColor;
        Light = "#4c566a";
        Link = "#88c0d0";
        LinkVisited = "#b48ead";
        Mid = "#3b4252";
        Midlight = "#434c5e";
        PlaceholderText = "#7b88a1";
        Shadow = "#2e3440";
        Text = "#d8dee9";
        ToolTipBase = "#3b4252";
        ToolTipText = "#d8dee9";
        Window = if cfg.variant == "bluish" then "#2e3440" else "#434c5e";
        WindowText = "#d8dee9";
      };
    };
  };
}
