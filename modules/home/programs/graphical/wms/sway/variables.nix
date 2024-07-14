{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.${namespace}.programs.graphical.wms.sway;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        # TODO: get what we can into sway
        # animations = {
        #   enabled = "yes";
        #   first_launch_animation = true; # fade in on first launch
        #
        #   # Some default animations, see https://wiki.sway.org/Configuring/Animations/ for more
        #   bezier = [
        #     "easein, 0.47, 0, 0.745, 0.715"
        #     "myBezier, 0.05, 0.9, 0.1, 1.05"
        #     "overshot, 0.13, 0.99, 0.29, 1.1"
        #     "scurve, 0.98, 0.01, 0.02, 0.98"
        #   ];
        #
        #   animation = [
        #     "border, 1, 10, default"
        #     "fade, 1, 10, default"
        #     "windows, 1, 5, overshot, popin 10%"
        #     "windowsOut, 1, 7, default, popin 10%"
        #     "workspaces, 1, 6, overshot, slide"
        #   ];
        # };
        #
        # debug = mkIf cfg.enableDebug {
        #   colored_stdout_logs = true;
        #   disable_logs = false;
        #   enable_stdout_logs = true;
        # };
        #
        # decoration = {
        #   active_opacity = 0.95;
        #   fullscreen_opacity = 1.0;
        #   inactive_opacity = 0.9;
        #   rounding = 10;
        #
        #   blur = {
        #     enabled = "yes";
        #     passes = 4;
        #     size = 5;
        #   };
        #
        #   drop_shadow = true;
        #   shadow_ignore_window = true;
        #   shadow_range = 20;
        #   shadow_render_power = 3;
        #   "col.shadow" = "0x55161925";
        #   "col.shadow_inactive" = "0x22161925";
        # };
        #
        # dwindle = {
        #   # See https://wiki.sway.org/Configuring/Dwindle-Layout/ for more
        #   # force_split = 0;
        #   preserve_split = true; # you probably want this
        #   pseudotile = false; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        #   no_gaps_when_only = false;
        #   special_scale_factor = 0.9;
        # };
        #
        # general = {
        #   # allow_tearing = true;
        #   border_size = 2;
        #   "col.active_border" = "rgba(7793D1FF)";
        #   "col.inactive_border" = "rgb(5e6798)";
        #   gaps_in = 5;
        #   gaps_out = 20;
        #   layout = "dwindle";
        # };
        #
        # gestures = {
        #   workspace_swipe = true;
        #   workspace_swipe_fingers = 3;
        #   workspace_swipe_invert = false;
        # };
        #
        # group = {
        #   # new windows in a group spawn after current or at group tail
        #   insert_after_current = true;
        #   # focus on the window that has just been moved out of the group
        #   focus_removed_window = true;
        #
        #   "col.border_active" = "rgba(88888888)";
        #   "col.border_inactive" = "rgba(00000088)";
        #
        #   groupbar = {
        #     # groupbar stuff
        #     # this removes the ugly gradient around grouped windows - which sucks
        #     gradients = false;
        #     font_size = 14;
        #
        #     # titles look ugly, and I usually know what I'm looking at
        #     render_titles = false;
        #
        #     # scrolling in the groupbar changes group active window
        #     scrolling = true;
        #   };
        # };
        #
        # input = {
        #   follow_mouse = 1;
        #   kb_layout = "us";
        #   numlock_by_default = true;
        #
        #   touchpad = {
        #     disable_while_typing = true;
        #     natural_scroll = "no";
        #     tap-to-click = true;
        #   };
        #
        #   sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        #   scroll_factor = 1.0;
        #   # repeat_delay = 500; # Mimic the responsiveness of mac setup
        #   # repeat_rate = 50; # Mimic the responsiveness of mac setup
        # };
        #
        # master = {
        #   # See https://wiki.sway.org/Configuring/Master-Layout/ for more
        #   new_status = "master";
        # };
        #
        # misc = {
        #   allow_session_lock_restore = true;
        #   disable_sway_logo = true;
        #
        #   # DPMS
        #   key_press_enables_dpms = true;
        #   mouse_move_enables_dpms = true;
        #
        #   vrr = 2;
        #
        #   # window swallowing
        #   enable_swallow = true; # hide windows that spawn other windows
        #   swallow_regex = "foot|thunar|nemo|wezterm"; # windows for which swallow is applied
        # };
        #
        # # unscale XWayland
        # xwayland = {
        #   force_zero_scaling = true;
        # };

        modifier = "Mod4";

        # default applications
        terminal = "${getExe config.programs.wezterm.package}";
      };
    };
  };
}
