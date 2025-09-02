{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;

  # Helper functions
  mkStartCommand =
    cmd:
    if (osConfig.programs.uwsm.enable or false) then "uwsm app -- ${cmd}" else "run-as-service ${cmd}";
  mkExecBind =
    bind:
    let
      parts = builtins.split "exec, " bind;
    in
    if builtins.length parts >= 3 then
      let
        pre = builtins.head parts;
        cmd = builtins.elemAt parts 2;
      in
      "${pre}exec, ${mkStartCommand cmd}"
    else
      bind; # Return unchanged if no "exec, " found
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # NOTE: different bind flags
        # l -> locked, will also work when an input inhibitor (e.g. a lockscreen) is active.
        # r -> release, will trigger on release of a key.
        # e -> repeat, will repeat when held.
        # n -> non-consuming, key/mouse events will be passed to the active window in addition to triggering the dispatcher.
        # m -> mouse, Mouse binds are binds that rely on mouse movement. They will have one less arg
        # t -> transparent, cannot be shadowed by other binds.
        # i -> ignore mods, will ignore modifiers.
        # "$mainMod" = "SUPER";
        # "$HYPER" = "SUPER_SHIFT_CTRL";
        # "$ALT-HYPER" = "SHIFT_ALT_CTRL";
        # "$RHYPER" = "SUPER_ALT_R_CTRL_R";
        # "$LHYPER" = "SUPER_ALT_L_CTRL_L";
        bind =
          let
            # Launcher binds
            launcherBinds = [
              "$mainMod, SPACE, exec, $($launcher)"
              "CTRL, SPACE, exec, $($launcher)"
              "ALT, SPACE, exec, $($launcher-alt)"
            ];

            # App launch binds
            appBinds = [
              "$mainMod, RETURN, exec, $term"
              "SUPER_SHIFT, RETURN, exec, $term zellij"
              "SUPER_SHIFT, P, exec, $color_picker"
              "$mainMod, B, exec, $browser"
              "SUPER_SHIFT, E, exec, $explorer"
              "$mainMod, E, exec, $term yazi"
              "$mainMod, L, exec, $screen-locker --immediate"
              "$mainMod, T, exec, $term btop"
              "$mainMod, N, exec, $notification_center -t -sw"
              "$mainMod, V, exec, $cliphist"
              # TODO: handle when you need to specify port manually `-p 5901`
              "$mainMod, W, exec, $looking-glass"
            ];

            # System binds (non-exec)
            systemBinds = [
              "$mainMod, Q, killactive,"
              "CTRL_SHIFT, Q, killactive,"
              "SUPER_ALT, V, togglefloating,"
              "$mainMod, P, pseudo, #dwindle"
              "$mainMod, J, togglesplit, #dwindle"
              "$mainMod, K, swapsplit, #dwindle"
              "$mainMod, F, fullscreen"
              # "SUPER_SHIFT, V, workspaceopt, allfloat"

              # kill window
              "$mainMod, Q, killactive,"
              "CTRL_SHIFT, Q, killactive,"
            ];

            # Screenshot binds
            screenshotBinds = [
              # Screenshot to clipboard
              ", Print, exec, $screenshot_active_clipboard"
              "SHIFT, Print, exec, $screenshot_area_clipboard"
              "SUPER, Print, exec, $screenshot_screen_clipboard"

              # Screenshot to file
              "CTRL, Print, exec, $screenshot_active_file"
              "CTRL_SHIFT, Print, exec, $screenshot_area_file"
              "SUPER_CTRL, Print, exec, $screenshot_screen_file"

              # Screenshot annotation
              "ALT, Print, exec, $screenshot_active_annotate"
              "ALT_CTRL, Print, exec, $screenshot_area_annotate"
              "ALT_SUPER, Print, exec, $screenshot_screen_annotate"

              # Screen recording
              "SUPER_CTRLALT, Print, exec, $screen-recorder screen"
              "SUPER_CTRLALTSHIFT, Print, exec, $screen-recorder area"
            ];

            # Window movement binds
            movementBinds = [
              # Window Focus
              "ALT,left,movefocus,l"
              "ALT,right,movefocus,r"
              "ALT,up,movefocus,u"
              "ALT,down,movefocus,d"
              # Move window
              "SUPER,left,movewindow,l"
              "SUPER,right,movewindow,r"
              "SUPER,up,movewindow,u"
              "SUPER,down,movewindow,d"
              # Resize Window
              "CTRL_SHIFT,h,resizeactive,-10% 0"
              "CTRL_SHIFT,l,resizeactive,10% 0"
            ];

            # Workspace management binds
            workspaceBinds = [
              # Swipe through existing workspaces with CTRL_ALT + left / right
              "CTRL_ALT, right, workspace, +1"
              "CTRL_ALT, l, workspace, +1"
              "CTRL_ALT, left, workspace, -1"
              "CTRL_ALT, h, workspace, -1"
              # Scroll through existing workspaces with CTRL_ALT + scroll
              "CTRL_ALT, mouse_down, workspace, e+1"
              "CTRL_ALT, mouse_up, workspace, e-1"
              # Move to workspace left/right
              "$ALT-HYPER, right, movetoworkspace, +1"
              "$ALT-HYPER, l, movetoworkspace, +1"
              "$ALT-HYPER, left, movetoworkspace, -1"
              "$ALT-HYPER, h, movetoworkspace, -1"
              # MOVING silently LEFT/RIGHT
              "SUPER_SHIFT, right, movetoworkspacesilent, +1"
              "SUPER_SHIFT, l, movetoworkspacesilent, +1"
              "SUPER_SHIFT, left, movetoworkspacesilent, -1"
              "SUPER_SHIFT, h, movetoworkspacesilent, -1"
            ];

            # Monitor management binds
            monitorBinds = [
              "SUPER_ALT, up, focusmonitor, u"
              "SUPER_ALT, k, focusmonitor, u"
              "SUPER_ALT, down, focusmonitor, d"
              "SUPER_ALT, j, focusmonitor, d"
              "SUPER_ALT, left, focusmonitor, l"
              "SUPER_ALT, h, focusmonitor, l"
              "SUPER_ALT, right, focusmonitor, r"
              "SUPER_ALT, l, focusmonitor, r"
              # moving current workspace to monitor
              "$HYPER,down,movecurrentworkspacetomonitor,d"
              "$HYPER,j,movecurrentworkspacetomonitor,d"
              "$HYPER,up,movecurrentworkspacetomonitor,u"
              "$HYPER,k,movecurrentworkspacetomonitor,u"
              "$HYPER,left,movecurrentworkspacetomonitor,l"
              "$HYPER,h,movecurrentworkspacetomonitor,l"
              "$HYPER,right,movecurrentworkspacetomonitor,r"
              "$HYPER,l,movecurrentworkspacetomonitor,r"
            ];

            # Special workspace binds
            specialBinds = [
              # Scratchpad
              "SUPER_SHIFT,grave,movetoworkspace,special:scratchpad"
              "SUPER,grave,togglespecialworkspace,scratchpad"
              # Inactive
              "ALT_SHIFT,grave,movetoworkspace,special:inactive"
              "ALT,grave,togglespecialworkspace,inactive"
            ];
          in
          # Apply mkStartCommand only to the exec commands
          (map mkExecBind (launcherBinds ++ appBinds ++ screenshotBinds))
          # Direct binds that don't need command wrapping
          ++ systemBinds
          ++ movementBinds
          ++ workspaceBinds
          ++ monitorBinds
          ++ specialBinds
          ++ [
            "$mainMod, I, exec, ${getExe pkgs.libnotify} \"$($window-inspector)\""
            "$mainMod, PERIOD, exec, ${getExe pkgs.smile}"
            "$CTRL_SHIFT, B, exec, ${getExe pkgs.killall} -SIGUSR1 $bar"
          ]
          ++ lib.optional (lib.elem pkgs.hyprlandPlugins.hyprexpo config.wayland.windowManager.hyprland.plugins) "SUPER, Escape, hyprexpo:expo, toggle"

          # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀
          # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀
          # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀
          # Switch workspaces with CTRL_ALT + [0-9]
          ++ (builtins.concatLists (
            builtins.genList (
              x:
              let
                ws =
                  let
                    c = (x + 1) / 10;
                  in
                  builtins.toString (x + 1 - (c * 10));
              in
              [
                "$CTRL_ALT, ${ws}, workspace, ${toString (x + 1)}"
                "$CTRL_ALT_SUPER, ${ws}, movetoworkspace, ${toString (x + 1)}"
                "$SUPER_SHIFT, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
              ]
            ) 10
          ));
        bindl = [
          # ░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█
          # ░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█
          # ░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀
          # Kill and restart crashed hyprlock
          "$mainMod, BackSpace, exec, pkill -SIGUSR1 hyprlock || WAYLAND_DISPLAY=wayland-1 $screen-locker"
          "$LHYPER, L, exec, systemctl --user exit"
          "$LHYPER, L, exit,"
          "$RHYPER, R, exec, reboot"
          "$RHYPER, P, exec, shutdown"

          # ░█▄█░█▀▀░█▀▄░▀█▀░█▀█
          # ░█░█░█▀▀░█░█░░█░░█▀█
          # ░▀░▀░▀▀▀░▀▀░░▀▀▀░▀░▀
          ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%+"
          ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%-"
          ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86MonBrightnessUp,exec,light -A 5"
          ",XF86MonBrightnessDown,exec,light -U 5"
          ",XF86AudioMedia,exec,${getExe pkgs.playerctl} play-pause"
          ",XF86AudioPlay,exec,${getExe pkgs.playerctl} play-pause"
          ",XF86AudioStop,exec,${getExe pkgs.playerctl} stop"
          ",XF86AudioPrev,exec,${getExe pkgs.playerctl} previous"
          ",XF86AudioNext,exec,${getExe pkgs.playerctl} next"
        ];
        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow #left click"
          "CTRL_SHIFT, mouse:272, movewindow #left click"
          "$mainMod, mouse:273, resizewindow #right click"
          "CTRL_SHIFT, mouse:273, resizewindow #right click"
        ];
      };
    };
  };
}
