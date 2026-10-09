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
    # Upstream #828bb8 misses 4.5:1 on bg_highlight; OKLCH lightness solved to
    # 4.6:1 against bg, bg_dark, and bg_highlight with hue and chroma kept.
    fg_dark = "#929cca";
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
  # Text and accent colors keep their OKLCH hue and chroma with lightness
  # solved to 4.6:1 against bg, bg_dark, bg_dark1, and bg_highlight, so they
  # read as text on day surfaces and as fills under light text.
  day = {
    bg = "#e1e2e7";
    bg_dark = "#e9e9ec";
    bg_dark1 = "#dcdcde";
    bg_highlight = "#c4c8da";
    blue = "#004cb4";
    blue0 = "#a8aecb";
    blue1 = "#00587d";
    blue2 = "#474b92";
    blue5 = "#005a73";
    blue6 = "#2e5857";
    blue7 = "#92a6d5";
    comment = "#9699a3";
    cyan = "#00587d";
    dark3 = "#8990b3";
    dark5 = "#6172b0";
    fg = "#264caa";
    fg_dark = "#404f8a";
    fg_gutter = "#a8aecb";
    green = "#3f5b1f";
    green1 = "#235c54";
    green2 = "#005c69";
    magenta = "#7121c2";
    magenta2 = "#ff007c";
    orange = "#8c3a00";
    purple = "#6836ab";
    red = "#a9002d";
    red1 = "#a21d25";
    teal = "#235c54";
    terminal_black = "#a1a6c5";
    yellow = "#6b4d1e";
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
