{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.programs.graphical.apps.zathura;
in
{
  options.${namespace}.programs.graphical.apps.zathura = {
    enable = mkEnableOption "zathura";
  };

  config = mkIf cfg.enable {
    programs.zathura = {
      enable = true;

      options = {
        adjust-open = "best-fit";
        font = "Iosevka 14";
        pages-per-row = "1";
        # recolor-lightcolor = "rgba(0,0,0,0)";
        scroll-full-overlap = "0.01";
        scroll-page-aware = "true";
        scroll-step = "100";
        selection-clipboard = "clipboard";
        selection-notification = true;
        zoom-min = "10";
      };
    };
  };
}
