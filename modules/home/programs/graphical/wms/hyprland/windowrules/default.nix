{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.programs.graphical.wms.hyprland;
in
{
  imports = [
    ./floating.nix
    ./fullscreen.nix
    ./idleinhibit.nix
    ./input.nix
    ./opacity.nix
    ./tearing.nix
    ./tiling.nix
    ./workspace.nix
  ];

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        windowrulev2 = [
          # fix xwayland apps
          "rounding 0, xwayland:1, floating:1"
          "center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$"
          "size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$"

          # xwaylandvideobridge
          "opacity 0.0 override 0.0 override,class:^(xwaylandvideobridge)$"
          "noanim,class:^(xwaylandvideobridge)$"
          "noinitialfocus,class:^(xwaylandvideobridge)$"
          "maxsize 1 1,class:^(xwaylandvideobridge)$"
          "noblur,class:^(xwaylandvideobridge)$"
        ];
      };
    };
  };
}
