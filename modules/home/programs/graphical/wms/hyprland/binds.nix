{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.wms.hyprland;

  # Helper functions
  mkStartCommand =
    let
      # Two-argument version: mkStartCommand { slice = "b"; } "command"
      withArgs =
        args: cmd:
        let
          slice = args.slice or null;
        in
        if (osConfig.programs.uwsm.enable or false) then
          "uwsm app ${if slice == null then "" else "-s ${slice}"} -- ${cmd}"
        else
          "run-as-service ${cmd}";

      # Single-argument version: mkStartCommand "command"
      withoutArgs =
        cmd:
        if (osConfig.programs.uwsm.enable or false) then "uwsm app -- ${cmd}" else "run-as-service ${cmd}";
    in
    args: if lib.isString args then withoutArgs args else withArgs args;

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

  # Helper to create submap binds with automatic reset
  # Usage: mkSubmapBinds { autoReset = true; } [ "bind1" "bind2" ]
  mkSubmapBinds =
    args: binds:
    let
      autoReset = args.autoReset or false;
      processedBinds = map mkExecBind binds;

      # Extract key combination from bind string (e.g., ", w, exec, ..." -> ", w")
      extractKey =
        bind:
        let
          parts = lib.splitString ", " bind;
        in
        if builtins.length parts >= 2 then
          "${builtins.elemAt parts 0}, ${builtins.elemAt parts 1}"
        else
          null;

      # Generate reset binds for each key
      resetBinds = lib.filter (x: x != null) (
        map (
          bind:
          let
            key = extractKey bind;
          in
          if key != null then "${key}, submap, reset" else null
        ) binds
      );
    in
    if autoReset then processedBinds ++ resetBinds else processedBinds;
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
              "CTRL, SPACE, exec, $($launcher)"
              "ALT, SPACE, exec, $($launcher-alt)"
              "$mainMod, SPACE, exec, $($launcher-backup)"
            ];

            # App launch binds
            appBinds = [
              # Interactive applications (app-graphical.slice)
              "$mainMod, RETURN, exec, $term"
              "SUPER_SHIFT, RETURN, exec, $term zellij"
              "SUPER_SHIFT, P, exec, $color_picker"
              "$mainMod, B, exec, $browser"
              "SUPER_SHIFT, E, exec, $explorer"
              "$mainMod, L, exec, $screen-locker --immediate"
              "$mainMod, N, exec, $notification_center -t -sw"
              "$mainMod, V, exec, $cliphist"
              # TODO: handle when you need to specify port manually `-p 5901`
              "$mainMod, W, exec, $looking-glass"
            ];

            # Background tools binds (background-graphical.slice)
            backgroundBinds = [
              "$mainMod, E, exec, ${mkStartCommand { slice = "b"; } "$term yazi"}"
              "$mainMod, T, exec, ${mkStartCommand { slice = "b"; } "$term btop"}"
            ];

            # System binds (non-exec) - keeping most used shortcuts
            systemBinds = [
              "$mainMod, Q, killactive,"
              "CTRL_SHIFT, Q, killactive,"
              "$mainMod, F, fullscreen" # Keep F for fullscreen as it's commonly used
            ];

            # Screenshot binds - keep Print key shortcuts for compatibility
            screenshotBinds = [
              # Quick screenshot shortcuts (original binds)
              ", Print, exec, $screenshot_active_clipboard"
              "SHIFT, Print, exec, $screenshot_area_clipboard"
              "SUPER, Print, exec, $screenshot_screen_clipboard"
            ];

            # Window movement binds - keeping basic movement
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
              # Enter monitor submap
              "$mainMod, M, submap, monitor"
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

            # System and window submap triggers
            submapTriggerBinds = [
              "$mainMod, S, submap, screenshot"
              "$mainMod, X, submap, system"
              "$mainMod, W, submap, window"
            ];
          in
          # Apply mkStartCommand only to the exec commands
          (map mkExecBind (launcherBinds ++ appBinds ++ screenshotBinds))
          # Background binds already have mkStartCommand applied
          ++ backgroundBinds
          # Direct binds that don't need command wrapping
          ++ systemBinds
          ++ movementBinds
          ++ workspaceBinds
          ++ monitorBinds
          ++ specialBinds
          ++ submapTriggerBinds
          ++ [
            "$mainMod, I, exec, notify-send \"$($window-inspector)\""
            "$mainMod, PERIOD, exec, smile"
            "$CTRL_SHIFT, B, exec, killall -SIGUSR1 $bar"
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
                  toString (x + 1 - (c * 10));
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

          # ░█▄█░█▀▀░█▀▄░▀█▀░█▀█
          # ░█░█░█▀▀░█░█░░█░░█▀█
          # ░▀░▀░▀▀▀░▀▀░░▀▀▀░▀░▀
          ",XF86AudioRaiseVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%+"
          ",XF86AudioLowerVolume,exec,wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%-"
          ",XF86AudioMute,exec,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86MonBrightnessUp,exec,light -A 5"
          ",XF86MonBrightnessDown,exec,light -U 5"
          ",XF86AudioMedia,exec,playerctl play-pause"
          ",XF86AudioPlay,exec,playerctl play-pause"
          ",XF86AudioStop,exec,playerctl stop"
          ",XF86AudioPrev,exec,playerctl previous"
          ",XF86AudioNext,exec,playerctl next"
        ];
        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mainMod, mouse:272, movewindow #left click"
          "CTRL_SHIFT, mouse:272, movewindow #left click"
          "$mainMod, mouse:273, resizewindow #right click"
          "CTRL_SHIFT, mouse:273, resizewindow #right click"
        ];
      };

      # Submap definitions for better keybind organization
      submaps = {
        screenshot = {
          settings = {
            bind =
              (mkSubmapBinds { autoReset = true; } [
                # Clipboard screenshots
                ", w, exec, $screenshot_active_clipboard" # current window
                ", a, exec, $screenshot_area_clipboard" # area selection
                ", s, exec, $screenshot_screen_clipboard" # full screen

                # File screenshots
                "SHIFT, w, exec, $screenshot_active_file"
                "SHIFT, a, exec, $screenshot_area_file"
                "SHIFT, s, exec, $screenshot_screen_file"

                # Annotated screenshots
                "ALT, w, exec, $screenshot_active_annotate"
                "ALT, a, exec, $screenshot_area_annotate"
                "ALT, s, exec, $screenshot_screen_annotate"

                # Screen recording
                ", r, exec, $screen-recorder screen"
                "SHIFT, r, exec, $screen-recorder area"
              ])
              ++ [
                # Exit submap
                ", escape, submap, reset"
                "SUPER, S, submap, reset"
              ];
          };
        };

        monitor = {
          settings = {
            bind = [
              # Focus monitor
              ", up, focusmonitor, u"
              ", k, focusmonitor, u"
              ", down, focusmonitor, d"
              ", j, focusmonitor, d"
              ", left, focusmonitor, l"
              ", h, focusmonitor, l"
              ", right, focusmonitor, r"
              ", l, focusmonitor, r"

              # Move workspace to monitor
              "SHIFT, up, movecurrentworkspacetomonitor, u"
              "SHIFT, k, movecurrentworkspacetomonitor, u"
              "SHIFT, down, movecurrentworkspacetomonitor, d"
              "SHIFT, j, movecurrentworkspacetomonitor, d"
              "SHIFT, left, movecurrentworkspacetomonitor, l"
              "SHIFT, h, movecurrentworkspacetomonitor, l"
              "SHIFT, right, movecurrentworkspacetomonitor, r"
              "SHIFT, l, movecurrentworkspacetomonitor, r"

              # Exit submap
              ", escape, submap, reset"
              "SUPER, M, submap, reset"
            ];
          };
        };

        system = {
          settings = {
            bind =
              (mkSubmapBinds { autoReset = true; } [
                ", l, exec, ${
                  if (osConfig.programs.uwsm.enable or false) then "uwsm stop" else "loginctl terminate-user $USER"
                }"
                ", r, exec, systemctl reboot"
                ", p, exec, systemctl poweroff"
              ])
              ++ [
                # Exit submap
                ", escape, submap, reset"
                "SUPER, X, submap, reset"
              ];
          };
        };

        window = {
          settings = {
            bind = [
              # Window operations
              ", f, fullscreen"
              ", v, togglefloating"
              ", i, togglefloating"
              ", i, pin"
              ", p, pseudo"
              ", j, togglesplit"
              ", k, swapsplit"

              # Resize operations
              ", h, resizeactive, -10% 0"
              ", l, resizeactive, 10% 0"
              "SHIFT, h, resizeactive, 0 -10%"
              "SHIFT, l, resizeactive, 0 10%"

              # Exit submap
              ", escape, submap, reset"
              "SUPER, R, submap, reset"
            ];
          };
        };
      };
    };
  };
}
