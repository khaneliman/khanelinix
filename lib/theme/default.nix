{ inputs }:
let
  inherit (inputs.nixpkgs.lib)
    concatMapStringsSep
    elem
    generators
    getExe
    removePrefix
    ;

  # qt5ct and qt6ct read a color scheme as one list per color group, in
  # QPalette::ColorRole order and as #AARRGGBB.
  qtctRoles = [
    "WindowText"
    "Button"
    "Light"
    "Midlight"
    "Dark"
    "Mid"
    "Text"
    "BrightText"
    "ButtonText"
    "Base"
    "Window"
    "Shadow"
    "Highlight"
    "HighlightedText"
    "Link"
    "LinkVisited"
    "AlternateBase"
    "NoRole"
    "ToolTipBase"
    "ToolTipText"
    "PlaceholderText"
  ];
  qtctDisabledRoles = [
    "WindowText"
    "Text"
    "ButtonText"
    "HighlightedText"
  ];
in
rec {
  mkColorScheme = name: colors: {
    inherit name colors;
    type = "colorScheme";
  };

  getColors = scheme: scheme.colors or { };

  variants = {
    light = "light";
    dark = "dark";
  };

  wallpaperTheme =
    config:
    if
      config ? khanelinix
      && config.khanelinix ? theme
      && config.khanelinix.theme ? wallpaper
      && config.khanelinix.theme.wallpaper ? theme
    then
      config.khanelinix.theme.wallpaper.theme
    else
      "catppuccin";

  wallpaperDir =
    {
      config,
      pkgs,
      theme ? null,
    }:
    let
      themeName = if theme != null then theme else wallpaperTheme config;
      prefix = if themeName == null || themeName == "" then "" else "${themeName}/";
    in
    "${pkgs.khanelinix.wallpapers}/share/wallpapers/${prefix}";

  wallpaperPath =
    {
      config,
      pkgs,
      name,
      theme ? null,
    }:
    let
      themeName = if theme != null then theme else wallpaperTheme config;
      prefix = if themeName == null || themeName == "" then "" else "${themeName}/";
    in
    "${pkgs.khanelinix.wallpapers}/share/wallpapers/${prefix}${name}";

  wallpaperPaths =
    {
      config,
      pkgs,
      names,
      theme ? null,
    }:
    map (
      name:
      wallpaperPath {
        inherit
          config
          pkgs
          theme
          name
          ;
      }
    ) names;

  # Renders a QPalette, as an attribute set of #RRGGBB colors keyed by color
  # role, to the text of a qt5ct or qt6ct color scheme file.
  qtctColorScheme =
    palette:
    let
      colors =
        disabled:
        concatMapStringsSep ", " (
          role:
          let
            # NoRole is never painted; it only has to keep the list aligned.
            color = palette.${if role == "NoRole" then "Window" else role};
            alpha = if disabled && elem role qtctDisabledRoles then "80" else "ff";
          in
          "#${alpha}${removePrefix "#" color}"
        ) qtctRoles;
    in
    generators.toINI { } {
      ColorScheme = {
        active_colors = colors false;
        disabled_colors = colors true;
        inactive_colors = colors false;
      };
    };

  # Migrated SCSS compilation utility
  # a function that takes a theme name and a source file and compiles it to CSS
  # compileSCSS "theme-name" "path/to/theme.scss" -> "$out/theme-name.css"
  # adapted from <https://github.com/spikespaz/dotfiles>
  compileSCSS =
    pkgs:
    {
      name,
      source,
      args ? "-t expanded",
    }:
    "${
      pkgs.runCommandLocal name { } ''
        mkdir -p $out
        ${getExe pkgs.sassc} ${args} '${source}' > $out/${name}.css
      ''
    }/${name}.css";
}
