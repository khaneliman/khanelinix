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
          "match:namespace anyrun, blur on"
          "match:namespace anyrun, blur_popups on"
          "match:namespace anyrun, dim_around on"
          "match:namespace sherlock, blur on"
          "match:namespace sherlock, blur_popups on"
          "match:namespace sherlock, dim_around on"
          "match:namespace walker, blur on"
          "match:namespace walker, blur_popups on"
          "match:namespace walker, dim_around on"
          "match:namespace vicinae, blur on"
          "match:namespace vicinae, blur_popups on"
          "match:namespace vicinae, dim_around on"
        ];
      };
    };
  };
}
