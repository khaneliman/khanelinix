{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    types
    ;

  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.theme.stylix;
in
{
  options.khanelinix.theme.stylix = {
    enable = mkEnableOption "stylix theme for applications";
    theme = mkOpt types.str "catppuccin-macchiato" "base16 theme file name";

    cursor = {
      name = mkOpt types.str "catppuccin-macchiato-blue-cursors" "The name of the cursor theme to apply.";
      package = mkOpt types.package (
        if pkgs.stdenv.hostPlatform.isLinux then
          pkgs.catppuccin-cursors.macchiatoBlue
        else
          pkgs.emptyDirectory
      ) "The package to use for the cursor theme.";
      size = mkOpt types.int 32 "The size of the cursor.";
    };

    icon = {
      name = mkOpt types.str "Papirus-Dark" "The name of the icon theme to apply.";
      package = mkOpt types.package (pkgs.catppuccin-papirus-folders.override {
        accent = "blue";
        flavor = "macchiato";
      }) "The package to use for the icon theme.";
    };
  };

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/${cfg.theme}.yaml";

      targets = {
        # FIXME: Stylix still writes removed NixOS kmscon options.
        kmscon.enable = false;
        gtk.enable = !config.khanelinix.theme.gtk.enable;
        qt.enable = !config.khanelinix.theme.qt.enable;
      };
    };
  };
}
