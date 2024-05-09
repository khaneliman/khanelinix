{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.graphical.apps.zathura;
in
{
  options.khanelinix.programs.graphical.apps.zathura = {
    enable = mkEnableOption "zathura";
  };

  config = mkIf cfg.enable {
    programs.zathura = {
      enable = true;
      extraConfig = "include catppuccin-mocha";

      options = {
        adjust-open = "best-fit";
        font = "Iosevka 14";
        pages-per-row = "1";
        recolor-lightcolor = "rgba(0,0,0,0)";
        scroll-full-overlap = "0.01";
        scroll-page-aware = "true";
        scroll-step = "100";
        selection-clipboard = "clipboard";
        selection-notification = true;
        zoom-min = "10";
      };
    };

    #TODO: add to the catppuccin package
    xdg.configFile."zathura/catppuccin-mocha".source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/catppuccin/zathura/main/src/catppuccin-mocha";
      hash = "sha256-/HXecio3My2eXTpY7JoYiN9mnXsps4PAThDPs4OCsAk=";
    };
  };
}
