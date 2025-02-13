{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (khanelinix-lib) mkBoolOpt mkOpt;

  cfg = config.khanelinix.theme.qt;
in
{
  options.khanelinix.theme.qt = with types; {
    enable = mkBoolOpt false "Whether to customize qt and apply themes.";

    theme = {
      name = mkOpt str "Catppuccin-Macchiato-Blue" "The name of the kvantum theme to apply.";
      package = mkOpt package (pkgs.catppuccin-kvantum.override {
        accent = "blue";
        variant = "macchiato";
      }) "The package to use for the theme.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages =
        with pkgs;
        [ cfg.theme.package ] ++ lib.optional config.khanelinix.suites.wlroots.enable kdePackages.qtwayland;
    };

    qt = {
      enable = true;

      platformTheme = "qt5ct";
      style = "kvantum";
    };
  };
}
