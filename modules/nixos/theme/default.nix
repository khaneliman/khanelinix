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
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.theme;
in
{
  options.khanelinix.theme = {
    enable = mkEnableOption "custom theme use for applications";

    name = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The primary name of the active theme (e.g., 'catppuccin', 'tokyonight').";
    };

    cursor = {
      name = mkOpt (types.nullOr types.str) null "The name of the cursor theme to apply.";
      package = mkOpt types.package pkgs.emptyDirectory "The package to use for the cursor theme.";
      size = mkOpt types.int 32 "The size of the cursor.";
    };

    icon = {
      name = mkOpt (types.nullOr types.str) null "The name of the icon theme to apply.";
      package = mkOpt types.package pkgs.emptyDirectory "The package to use for the icon theme.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.emptyDirectory;
      description = "The primary theme package to install system-wide.";
    };
  };

  config = mkIf cfg.enable {
    warnings = lib.mkIf (cfg.name == null) [
      "khanelinix.theme is enabled, but no theme name (e.g. catppuccin, tokyonight, nord) is configured. You may have forgotten to enable a concrete theme module."
    ];

    environment = {
      sessionVariables = lib.mkMerge [
        (lib.mkIf (cfg.cursor.name != null) {
          CURSOR_THEME = cfg.cursor.name;
          XCURSOR_THEME = cfg.cursor.name;
          XCURSOR_SIZE = "${toString cfg.cursor.size}";
        })
      ];

      systemPackages = [
        cfg.cursor.package
        cfg.icon.package
        cfg.package
      ];
    };
  };
}
