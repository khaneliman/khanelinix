let
  # Base storm palette
  storm = {
    bg = "#24283b";
    bg_dark = "#1f2335";
    bg_dark1 = "#1b1e2d";
    bg_highlight = "#292e42";
    blue = "#7aa2f7";
    blue0 = "#3d59a1";
    blue1 = "#2ac3de";
    blue2 = "#0db9d7";
    blue5 = "#89ddff";
    blue6 = "#b4f9f8";
    blue7 = "#394b70";
    comment = "#565f89";
    cyan = "#7dcfff";
    dark3 = "#545c7e";
    dark5 = "#737aa2";
    fg = "#c0caf5";
    fg_dark = "#a9b1d6";
    fg_gutter = "#3b4261";
    green = "#9ece6a";
    green1 = "#73daca";
    green2 = "#41a6b5";
    magenta = "#bb9af7";
    magenta2 = "#ff007c";
    orange = "#ff9e64";
    purple = "#9d7cd8";
    red = "#f7768e";
    red1 = "#db4b4b";
    teal = "#1abc9c";
    terminal_black = "#414868";
    yellow = "#e0af68";
    git = {
      add = "#449dab";
      change = "#6183bb";
      delete = "#914c54";
    };
  };

  # Night variant - based on storm with darker backgrounds
  night = storm // {
    bg = "#1a1b26";
    bg_dark = "#16161e";
    bg_dark1 = "#0C0E14";
  };

  # Moon variant - unique palette
  moon = {
    bg = "#222436";
    bg_dark = "#1e2030";
    bg_dark1 = "#191B29";
    bg_highlight = "#2f334d";
    blue = "#82aaff";
    blue0 = "#3e68d7";
    blue1 = "#65bcff";
    blue2 = "#0db9d7";
    blue5 = "#89ddff";
    blue6 = "#b4f9f8";
    blue7 = "#394b70";
    comment = "#636da6";
    cyan = "#86e1fc";
    dark3 = "#545c7e";
    dark5 = "#737aa2";
    fg = "#c8d3f5";
    fg_dark = "#828bb8";
    fg_gutter = "#3b4261";
    green = "#c3e88d";
    green1 = "#4fd6be";
    green2 = "#41a6b5";
    magenta = "#c099ff";
    magenta2 = "#ff007c";
    orange = "#ff966c";
    purple = "#fca7ea";
    red = "#ff757f";
    red1 = "#c53b53";
    teal = "#4fd6be";
    terminal_black = "#444a73";
    yellow = "#ffc777";
    git = {
      add = "#b8db87";
      change = "#7ca1f2";
      delete = "#e26a75";
    };
  };

  # Day variant - inverted/light version based on storm
  # Note: This is a simplified version. The actual day variant
  # uses Lua's deepcopy and invert/blend functions which are
  # complex to replicate in Nix. This provides the essential colors.
  day = {
    bg = "#e1e2e7";
    bg_dark = "#e9e9ec";
    bg_dark1 = "#dcdcde";
    bg_highlight = "#c4c8da";
    blue = "#2e7de9";
    blue0 = "#a8aecb";
    blue1 = "#007197";
    blue2 = "#4e529a";
    blue5 = "#006a83";
    blue6 = "#2e5857";
    blue7 = "#92a6d5";
    comment = "#9699a3";
    cyan = "#007197";
    dark3 = "#8990b3";
    dark5 = "#6172b0";
    fg = "#3760bf";
    fg_dark = "#6172b0";
    fg_gutter = "#a8aecb";
    green = "#587539";
    green1 = "#387068";
    green2 = "#38919f";
    magenta = "#9854f1";
    magenta2 = "#ff007c";
    orange = "#b15c00";
    purple = "#7847bd";
    red = "#f52a65";
    red1 = "#c64343";
    teal = "#387068";
    terminal_black = "#a1a6c5";
    yellow = "#8c6c3e";
    git = {
      add = "#387068";
      change = "#506d9c";
      delete = "#c47981";
    };
  };
in
{
  # Export all color palettes
  palette = {
    inherit
      storm
      night
      moon
      day
      ;
  };

  # Helper to get palette by variant name
  getVariant =
    variant:
    {
      "storm" = storm;
      "night" = night;
      "moon" = moon;
      "day" = day;
    }
    .${variant} or night; # Default to night if variant not found
}
