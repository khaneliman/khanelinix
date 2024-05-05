{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        bind =
          [
            # ░█▀█░█▀█░█▀█░░░█░░░█▀█░█░█░█▀█░█▀▀░█░█░█▀▀░█▀▄░█▀▀
            # ░█▀█░█▀▀░█▀▀░░░█░░░█▀█░█░█░█░█░█░░░█▀█░█▀▀░█▀▄░▀▀█
            # ░▀░▀░▀░░░▀░░░░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀
            "$mainMod, RETURN, exec, $term"
            "SUPER_SHIFT, RETURN, exec, $term zellij"
            "SUPER_ALT, RETURN, exec, $term --title floatterm --single-instance"
            "$mainMod, Q, killactive,"
            "CTRL_SHIFT, Q, killactive,"
            "SUPER_SHIFT, P, exec, $color_picker"
            "$mainMod, B, exec, $browser"
            "SUPER_SHIFT, E, exec, $explorer"
            "$mainMod, E, exec, $term yazi"
            "$mainMod, SPACE, exec, $launcher"
            "CTRL, SPACE, exec, $launcher"
            "CTRL_SHIFT, SPACE, exec, $launcher_shift"
            "$mainMod, A, exec, $launchpad"
            "$mainMod, L, exec, $screen-locker --immediate"
            "$mainMod, T, exec, $term btop"
            "$mainMod, N, exec, $notification_center -t -sw"
            # "SUPER, V, clipman pick -t rofi
            "$mainMod, V, exec, $cliphist"
            "$mainMod, W, exec, $looking-glass"
            "$mainMod, I, exec, ${getExe pkgs.libnotify} \"$($window-inspector)\""

            # ░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█
            # ░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█
            # ░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀
            "$LHYPER, L, exec, systemctl --user exit"
            "$LHYPER, L, exit,"
            # "$RHYPER, R, exec, reboot" # TODO: fix
            # "$RHYPER, P, exec, shutdown" # TODO: fix
            "$LHYPER, T, exec, ${getExe pkgs.libnotify} 'test left'"
            "$RHYPER, T, exec, ${getExe pkgs.libnotify} 'test right'"

            # ░█▀▀░█▀▀░█▀▄░█▀▀░█▀▀░█▀█░█▀▀░█░█░█▀█░▀█▀
            # ░▀▀█░█░░░█▀▄░█▀▀░█▀▀░█░█░▀▀█░█▀█░█░█░░█░
            # ░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░░▀░
            # File
            ", Print, exec, $grimblast_active_file"
            "SHIFT, Print, exec, $grimblast_area_file"
            # "SHIFT_CTRL, S, exec, $grimblast_area_file"
            "SUPER, Print, exec, $grimblast_screen_file"

            # Area / Window
            "ALT, Print, exec, $grimblast_active_swappy"
            "ALT_CTRL, Print, exec, $grimblast_area_swappy"
            "ALT_SUPER, Print, exec, $grimblast_screen_swappy"
            # "SUPER_CTRL_SHIFT, S, exec, $grimblast_screen_swappy"

            # Clipboard
            "CTRL, Print, exec, $grimblast_active_clipboard"
            "CTRL_SHIFT, Print, exec, $grimblast_area_clipboard"
            "SUPER_CTRL, Print, exec, $grimblast_screen_clipboard"

            # Screen recording
            "SUPER_CTRLALT, Print, exec, $screen-recorder screen"
            "SUPER_CTRLALTSHIFT, Print, exec, $screen-recorder area"

            # ░█░░░█▀█░█░█░█▀█░█░█░▀█▀
            # ░█░░░█▀█░░█░░█░█░█░█░░█░
            # ░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░░▀░
            "SUPER_ALT, V, togglefloating,"
            "$mainMod, P, pseudo, # dwindle"
            "$mainMod, J, togglesplit, # dwindle"
            "$mainMod, F, fullscreen"
            # "SUPER_SHIFT, V, workspaceopt, allfloat"

            # ░█░█░▀█▀░█▀█░█▀▄░█▀█░█░█
            # ░█▄█░░█░░█░█░█░█░█░█░█▄█
            # ░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀
            # WINDOWS FOCUS
            "ALT,left,movefocus,l"
            "ALT,right,movefocus,r"
            "ALT,up,movefocus,u"
            "ALT,down,movefocus,d"
            # Move window
            "SUPER,left,movewindow,l"
            "SUPER,right,movewindow,r"
            "SUPER,up,movewindow,u"
            "SUPER,down,movewindow,d"

            "CTRL_SHIFT,h,resizeactive,-10% 0"
            "CTRL_SHIFT,l,resizeactive,10% 0"

            # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀
            # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀
            # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀
            # Swipe through existing workspaces with CTRL_ALT + left / right
            "CTRL_ALT, right, workspace, +1"
            "CTRL_ALT, left, workspace, -1"

            # Move to workspace left/right
            "CTRL_ALT_SUPER, right, movetoworkspace, +1"
            "CTRL_ALT_SUPER, left, movetoworkspace, -1"

            # Scroll through existing workspaces with CTRL_ALT + scroll
            "CTRL_ALT, mouse_down, workspace, e+1"
            "CTRL_ALT, mouse_up, workspace, e-1"

            # MOVING silently LEFT/RIGHT
            "SUPER_SHIFT, right, movetoworkspacesilent, +1"
            "SUPER_SHIFT, left, movetoworkspacesilent, -1"

            # Scratchpad
            "SUPER_SHIFT,grave,movetoworkspace,special:scratchpad"
            "SUPER,grave,togglespecialworkspace,scratchpad"

            # Inactive
            "ALT_SHIFT,grave,movetoworkspace,special:inactive"
            "ALT,grave,togglespecialworkspace,inactive"

            # ░█▄█░█▀█░█▀█░▀█▀░▀█▀░█▀█░█▀▄
            # ░█░█░█░█░█░█░░█░░░█░░█░█░█▀▄
            # ░▀░▀░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀
            # simple movement between monitors
            "SUPER_CTRL, up, focusmonitor, u"
            "SUPER_CTRL, down, focusmonitor, d"
            "SUPER_CTRL, left, focusmonitor, l"
            "SUPER_CTRL, right, focusmonitor, r"

            # moving current workspace to monitor
            "SUPER_CTRL_SHIFT,down,movecurrentworkspacetomonitor,d"
            "SUPER_CTRL_SHIFT,up,movecurrentworkspacetomonitor,u"
            "SUPER_CTRL_SHIFT,left,movecurrentworkspacetomonitor,l"
            "SUPER_CTRL_SHIFT,right,movecurrentworkspacetomonitor,r"

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
          ]
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
          "$mainMod, BackSpace, exec, pkill -SIGUSR1 hyprlock || WAYLAND_DISPLAY=wayland-1 $screen-locker  --immediate"
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
