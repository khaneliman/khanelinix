{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.graphical.file-managers.thunar;
in
{
  options.${namespace}.programs.graphical.file-managers.thunar = {
    enable = lib.mkEnableOption "the xfce file manager";
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
    };
  };
}
