{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.addons.uwsm;
in
{
  options.${namespace}.programs.graphical.addons.uwsm = {
    enable = mkBoolOpt false "Whether or not to enable uwsm";
  };

  config = mkIf cfg.enable {
    programs.uwsm.enable = true;

    khanelinix.home = {
      configFile = {
        "uwsm/env".text = ''
          export CLUTTER_BACKEND=wayland
          export GDK_BACKEND=wayland,x11
          export MOZ_ENABLE_WAYLAND=1
          export MOZ_USE_XINPUT2=1
          export WLR_DRM_NO_ATOMIC=1
          export XDG_SESSION_TYPE=wayland
          export _JAVA_AWT_WM_NONREPARENTING=1
          export __GL_GSYNC_ALLOWED=0
          export __GL_VRR_ALLOWED=0
        '';
        # Debug variables (commented out by default)
        #export AQ_TRACE="1"
        #export HYPRLAND_LOG_WLR="1"
        #export HYPRLAND_TRACE="1"
      };
    };
  };
}
