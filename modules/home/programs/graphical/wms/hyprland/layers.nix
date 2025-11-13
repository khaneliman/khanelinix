{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        layerrule = [
          "blur, anyrun"
          "blurpopups, anyrun"
          "dimaround, anyrun"
          "blur, sherlock"
          "blurpopups, sherlock"
          "dimaround, sherlock"
          "blur, walker"
          "blurpopups, walker"
          "dimaround, walker"
          "blur, vicinae"
          "blurpopups, vicinae"
          "dimaround, vicinae"
        ];
      };
    };
  };
}
