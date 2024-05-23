{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.theme.qt;
in
{
  options.${namespace}.theme.qt = with types; {
    enable = mkBoolOpt false "Whether to customize qt and apply themes.";

    theme = {
      name = mkOpt str "Catppuccin-Macchiato-Blue" "The name of the kvantum theme to apply.";
      package = mkOpt package (pkgs.catppuccin-kvantum.override {
        accent = "Blue";
        variant = "Macchiato";
      }) "The package to use for the theme.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages =
        with pkgs;
        [ cfg.theme.package ]
        ++ lib.optional config.${namespace}.suites.wlroots.enable libsForQt5.qt5.qtwayland;
    };

    qt = {
      enable = true;

      platformTheme = "qt5ct";
      style = "kvantum";
    };
  };
}
