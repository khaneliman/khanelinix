{ inputs }:
let
  inherit (inputs.nixpkgs.lib) getExe;
in
{
  # Common theme utilities
  mkColorScheme = name: colors: {
    inherit name colors;
    type = "colorScheme";
  };

  # Extract colors from a scheme
  getColors = scheme: scheme.colors or { };

  # Theme variants
  variants = {
    light = "light";
    dark = "dark";
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
