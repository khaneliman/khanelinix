{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.desktop.theme;

  catppuccinAccents = [
    "rosewater"
    "flamingo"
    "pink"
    "mauve"
    "red"
    "maroon"
    "peach"
    "yellow"
    "green"
    "teal"
    "sky"
    "sapphire"
    "blue"
    "lavender"
  ];
  catppuccinVariants = [
    "latte"
    "frappe"
    "macchiato"
    "mocha"
  ];
in
{
  options.khanelinix.desktop.theme = {
    enable = mkEnableOption "Enable custom theme use for applications.";

    cursor = {
      name = mkOpt types.str "Catppuccin-Macchiato-Blue-Cursors" "The name of the cursor theme to apply.";
      package =
        mkOpt types.package pkgs.catppuccin-cursors.macchiatoBlue
          "The package to use for the cursor theme.";
      size = mkOpt types.int 32 "The size of the cursor.";
    };

    icon = {
      name = mkOpt types.str "breeze-dark" "The name of the icon theme to apply.";
      package = mkOpt types.package pkgs.libsForQt5.breeze-icons "The package to use for the icon theme.";
    };

    selectedTheme = mkOption {
      type = types.submodule {
        options = {
          name = mkOpt types.str "catppuccin" "The theme to use.";
          accent = mkOption {
            type = types.enum catppuccinAccents;
            default = "blue";
            description = ''
              An optional theme accent.
            '';
          };
          variant = mkOption {
            type = types.enum catppuccinVariants;
            default = "macchiato";
            description = ''
              An optional theme variant.
            '';
          };
        };
      };
      default = {
        name = "catppuccin";
        accent = "blue";
        variant = "macchiato";
      };
      description = "Theme to use for applications.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.catppuccin.override { inherit (cfg.selectedTheme) accent variant; };
      description = ''
        The `spotifyd` package to use.
        Can be used to specify extensions.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        CURSOR_THEME = cfg.cursor.name;
        XCURSOR_SIZE = "${toString cfg.cursor.size}";
        XCURSOR_THEME = cfg.cursor.name;
      };

      systemPackages = [
        cfg.cursor.package
        cfg.icon.package
        cfg.selectedTheme.package
      ];
    };
  };
}
