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
        window_rule = [
          # fix xwayland apps
          {
            match.xwayland = true;
            match.float = true;
            rounding = 0;
          }
          {
            match.class = "^(.*jetbrains.*)$";
            match.title = "^(Confirm Exit|Open Project|win424|win201|splash)$";
            center = true;
          }
          {
            match.class = "^(.*jetbrains.*)$";
            match.title = "^(splash)$";
            size = "640 400";
          }

          # xwaylandvideobridge
          {
            match.class = "^(xwaylandvideobridge)$";
            opacity = "0.0 override 0.0 override";
          }
          {
            match.class = "^(xwaylandvideobridge)$";
            no_anim = true;
          }
          {
            match.class = "^(xwaylandvideobridge)$";
            no_initial_focus = true;
          }
          {
            match.class = "^(xwaylandvideobridge)$";
            max_size = "1 1";
          }
          {
            match.class = "^(xwaylandvideobridge)$";
            no_blur = true;
          }
        ];
      };
    };
  };
}
