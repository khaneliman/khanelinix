{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.file-managers.thunar;
in
{
  options.${namespace}.programs.graphical.file-managers.thunar = {
    enable = mkBoolOpt false "Whether to enable the xfce file manager.";
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
    };
  };
}
