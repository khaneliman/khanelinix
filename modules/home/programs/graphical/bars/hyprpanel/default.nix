{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    ;

  cfg = config.${namespace}.programs.graphical.bars.hyprpanel;
in
{
  options.${namespace}.programs.graphical.bars.hyprpanel = {
    enable = lib.mkEnableOption "hyprpanel in the desktop environment";
  };

  config = mkIf cfg.enable {
    programs.hyprpanel = {
      enable = true;
      hyprland.enable = true;
      overwrite.enable = true;
    };
  };
}
