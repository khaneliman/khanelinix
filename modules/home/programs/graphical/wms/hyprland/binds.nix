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
  toLua = lib.generators.toLua { };
  lua = lib.generators.mkLuaInline;

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

  enabledLaunchers =
    let
      inherit (config.khanelinix.programs.graphical) launchers;
    in
    lib.flatten [
      (lib.optional launchers.vicinae.enable "vicinae open")
      (lib.optional launchers.anyrun.enable "anyrun")
      (lib.optional launchers.walker.enable "walker")
      (lib.optional launchers.sherlock.enable "sherlock")
      (lib.optional launchers.rofi.enable "rofi -show drun")
    ];

  dmenuLauncher =
    let
      inherit (config.khanelinix.programs.graphical) launchers;
      enabledDmenuLaunchers = lib.flatten [
        (lib.optional launchers.vicinae.enable "vicinae dmenu")
        (lib.optional launchers.anyrun.enable "anyrun --show-results-immediately true")
        (lib.optional launchers.walker.enable "walker --stream")
        (lib.optional launchers.sherlock.enable "sherlock")
        (lib.optional launchers.rofi.enable "rofi -dmenu")
      ];
    in
    builtins.head enabledDmenuLaunchers;

  commandReplacements =
    let
      launcherCount = builtins.length enabledLaunchers;
      magick = lib.getExe' pkgs.imagemagick "magick";
      screenshotPath =
        if config.xdg.userDirs.enable then
          "${config.xdg.userDirs.pictures}/screenshots"
        else
          "${config.home.homeDirectory}/Pictures/screenshots";
      getDateTime = lib.getExe (
        pkgs.writeShellScriptBin "getDateTime" /* bash */ ''
          echo $(date +'%Y%m%d_%H%M%S')
        ''
      );
      screenshotTool =
        if config.programs.hyprshot.enable then
          {
            area = "hyprshot -m region --freeze --raw | ${magick} convert png:- ppm:-";
            active = "hyprshot -m active -m window --raw | ${magick} convert png:- ppm:-";
            screen = "hyprshot -m output --raw | ${magick} convert png:- ppm:-";
            areaFile = "hyprshot -m region --freeze -o \"${screenshotPath}\" -f \"$(${getDateTime}).png\"";
            activeFile = "hyprshot -m active -m window -o \"${screenshotPath}\" -f \"$(${getDateTime}).png\"";
            screenFile = "hyprshot -m output -o \"${screenshotPath}\" -f \"$(${getDateTime}).png\"";
            areaClipboard = "hyprshot -m region --freeze --clipboard-only";
            activeClipboard = "hyprshot -m active -m window --clipboard-only";
            screenClipboard = "hyprshot -m output --clipboard-only";
          }
        else
          {
            area = "grimblast --freeze --type ppm save area -";
            active = "grimblast --type ppm save active -";
            screen = "grimblast --type ppm save screen -";
            areaFile = "grimblast --freeze --notify save area \"${screenshotPath}/$(${getDateTime}).png\"";
            activeFile = "grimblast --notify save active \"${screenshotPath}/$(${getDateTime}).png\"";
            screenFile = "grimblast --notify save screen \"${screenshotPath}/$(${getDateTime}).png\"";
            areaClipboard = "grimblast --freeze --notify copy area";
            activeClipboard = "grimblast --notify copy active";
            screenClipboard = "grimblast --freeze --notify copy screen";
          };
      annotationTool =
        if config.khanelinix.programs.graphical.addons.satty.enable then
          "satty --filename -"
        else
          "swappy -f -";
    in
    [
      {
        from = "$($launcher)";
        to = lib.optionalString (launcherCount > 0) (builtins.elemAt enabledLaunchers 0);
      }
      {
        from = "$($launcher-alt)";
        to = lib.optionalString (launcherCount > 1) (builtins.elemAt enabledLaunchers 1);
      }
      {
        from = "$($launcher-backup)";
        to = lib.optionalString (launcherCount > 2) (builtins.elemAt enabledLaunchers 2);
      }
      {
        from = "$mainMod";
        to = "SUPER";
      }
      {
        from = "$HYPER";
        to = "SUPER_SHIFT_CTRL";
      }
      {
        from = "$ALT-HYPER";
        to = "SHIFT_ALT_CTRL";
      }
      {
        from = "$RHYPER";
        to = "SUPER_ALT_R_CTRL_R";
      }
      {
        from = "$LHYPER";
        to = "SUPER_ALT_L_CTRL_L";
      }
      {
        from = "$CTRL_SHIFT";
        to = "CTRL_SHIFT";
      }
      {
        from = "$CTRL_ALT";
        to = "CTRL_ALT";
      }
      {
        from = "$CTRL_ALT_SUPER";
        to = "CTRL_ALT_SUPER";
      }
      {
        from = "$SUPER_SHIFT";
        to = "SUPER_SHIFT";
      }
      {
        from = "$term";
        to = "kitty";
      }
      {
        from = "$browser";
        to = lib.getExe config.programs.firefox.package;
      }
      {
        from = "$explorer";
        to = "nautilus";
      }
      {
        from = "$screen-locker";
        to = "hyprlock";
      }
      {
        from = "$notification_center";
        to = "swaync-client";
      }
      {
        from = "$cliphist";
        to = "cliphist list  | tr -d '\\000' | ${dmenuLauncher} | cliphist decode | wl-copy";
      }
      {
        from = "$looking-glass";
        to = "looking-glass-client";
      }
      {
        from = "$color_picker";
        to = "hyprpicker -a && (${magick} convert -size 32x32 xc:$(wl-paste) /tmp/color.png && notify-send \"Color Code:\" \"$(wl-paste)\" -h \"string:bgcolor:$(wl-paste)\" --icon /tmp/color.png -u critical -t 4000)";
      }
      {
        from = "$bar";
        to = ".waybar-wrapped";
      }
      {
        from = "$window-inspector";
        to = "hyprprop";
      }
      {
        from = "$screenshot_active_clipboard";
        to = screenshotTool.activeClipboard;
      }
      {
        from = "$screenshot_area_clipboard";
        to = screenshotTool.areaClipboard;
      }
      {
        from = "$screenshot_screen_clipboard";
        to = screenshotTool.screenClipboard;
      }
      {
        from = "$screenshot_active_file";
        to = screenshotTool.activeFile;
      }
      {
        from = "$screenshot_area_file";
        to = screenshotTool.areaFile;
      }
      {
        from = "$screenshot_screen_file";
        to = screenshotTool.screenFile;
      }
      {
        from = "$screenshot_active_annotate";
        to = "${screenshotTool.active} | ${annotationTool}";
      }
      {
        from = "$screenshot_area_annotate";
        to = "${screenshotTool.area} | ${annotationTool}";
      }
      {
        from = "$screenshot_screen_annotate";
        to = "${screenshotTool.screen} | ${annotationTool}";
      }
      {
        from = "$screen-recorder";
        to = "record_screen";
      }
    ];

  replaceCommandVars =
    value:
    lib.replaceStrings (map (replacement: replacement.from) commandReplacements) (map (
      replacement: replacement.to
    ) commandReplacements) value;

  normalizeDirection =
    direction:
    {
      l = "left";
      r = "right";
      u = "up";
      d = "down";
    }
    .${direction} or direction;

  mkExecRawDispatcher =
    dispatcher: args:
    "hl.dsp.exec_raw(${
      toLua (lib.concatStringsSep " " ([ dispatcher ] ++ lib.optional (args != "") args))
    })";

  mkHyprshotOutputDispatcher = args: ''
    function()
      local command = ${toLua args}
      local monitor = hl.get_active_monitor()
      if monitor ~= nil and monitor.name ~= nil then
        command = command:gsub("hyprshot %-m output", "hyprshot -m output -m " .. string.format("%q", monitor.name), 1)
      end
      hl.exec_cmd(command)
    end
  '';

  mkRecordScreenDispatcher = args: ''
    function()
      local monitor = hl.get_active_monitor()
      if monitor == nil or monitor.name == nil or monitor.width == nil or monitor.height == nil then
        hl.exec_cmd(${toLua args})
        return
      end
      hl.exec_cmd(${toLua args} .. " " .. string.format("%q", monitor.name) .. " " .. tostring(monitor.width) .. " " .. tostring(monitor.height))
    end
  '';

  mkExecDispatcher =
    args:
    if lib.hasSuffix "record_screen screen" args then
      mkRecordScreenDispatcher args
    else if lib.hasInfix "hyprshot -m output" args then
      mkHyprshotOutputDispatcher args
    else
      "hl.dsp.exec_cmd(${toLua args})";

  dispatcherMap = {
    submap = args: "hl.dsp.submap(${toLua args})";
    killactive = _: "hl.dsp.window.close()";
    fullscreen = _: "hl.dsp.window.fullscreen()";
    movefocus = args: "hl.dsp.focus({ direction = ${toLua (normalizeDirection args)} })";
    movewindow =
      args:
      if args == "" then
        "hl.dsp.window.drag()"
      else
        "hl.dsp.window.move({ direction = ${toLua (normalizeDirection args)} })";
    resizewindow = _: "hl.dsp.window.resize()";
    workspace = args: "hl.dsp.focus({ workspace = ${toLua args} })";
    movetoworkspace = args: "hl.dsp.window.move({ workspace = ${toLua args}, follow = true })";
    movetoworkspacesilent = args: "hl.dsp.window.move({ workspace = ${toLua args}, follow = false })";
    focusmonitor = args: "hl.dsp.focus({ monitor = ${toLua args} })";
    movecurrentworkspacetomonitor = args: "hl.dsp.workspace.move({ monitor = ${toLua args} })";
    togglespecialworkspace = args: "hl.dsp.workspace.toggle_special(${toLua args})";
    togglefloating = _: ''hl.dsp.window.float({ action = "toggle" })'';
    pin = _: "hl.dsp.window.pin()";
    pseudo = _: "hl.dsp.window.pseudo()";
  };

  mkDispatcher =
    dispatcher: args:
    if dispatcher == "exec" then
      mkExecDispatcher args
    else
      dispatcherMap.${dispatcher} or (mkExecRawDispatcher dispatcher) args;

  mkLuaBindWith =
    opts: bind:
    let
      parts = map lib.trim (lib.splitString "," (replaceCommandVars bind));
      mods = builtins.elemAt parts 0;
      key = builtins.elemAt parts 1;
      dispatcher = builtins.elemAt parts 2;
      args = lib.concatStringsSep "," (lib.drop 3 parts);
      keyCombo = lib.concatStringsSep " + " (
        lib.filter (part: part != "") [
          (lib.replaceStrings [ "_" ] [ " + " ] mods)
          key
        ]
      );
    in
    {
      _args = [
        keyCombo
        (lua (mkDispatcher dispatcher args))
      ]
      ++ lib.optional (opts != { }) opts;
    };

  mkLuaBind = mkLuaBindWith { };
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
            launcherBinds =
              let
                inherit (config.khanelinix.programs.graphical) launchers;
                enabledLaunchers = lib.flatten [
                  (lib.optional launchers.vicinae.enable "vicinae open")
                  (lib.optional launchers.anyrun.enable "anyrun")
                  (lib.optional launchers.walker.enable "walker")
                  (lib.optional launchers.sherlock.enable "sherlock")
                  (lib.optional launchers.rofi.enable "rofi -show drun")
                ];
                count = builtins.length enabledLaunchers;
              in
              lib.optional (count > 0) "CTRL, SPACE, exec, $($launcher)"
              ++ lib.optional (count > 1) "ALT, SPACE, exec, $($launcher-alt)"
              ++ lib.optional (count > 2) "$mainMod, SPACE, exec, $($launcher-backup)";

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
              "$mainMod, R, submap, window"
            ];

            lockedBinds = [
              "$mainMod, BackSpace, exec, pkill -SIGUSR1 hyprlock || WAYLAND_DISPLAY=wayland-1 $screen-locker"
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

            mouseBinds = [
              "$mainMod, mouse:272, movewindow"
              "CTRL_SHIFT, mouse:272, movewindow"
              "$mainMod, mouse:273, resizewindow"
              "CTRL_SHIFT, mouse:273, resizewindow"
            ];
          in
          (map mkLuaBind (
            (map mkExecBind (launcherBinds ++ appBinds ++ screenshotBinds))
            ++ backgroundBinds
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
            ))
          ))
          ++ map (mkLuaBindWith { locked = true; }) lockedBinds
          ++ map (mkLuaBindWith { mouse = true; }) mouseBinds;
      };

      # Submap definitions for better keybind organization
      submaps = {
        screenshot = {
          onDispatch = "reset";
          settings = {
            bind = map mkLuaBind (
              (map mkExecBind [
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
              ]
            );
          };
        };

        monitor = {
          settings = {
            bind = map mkLuaBind [
              # Focus monitor
              ", up, focusmonitor, DP-3"
              ", k, focusmonitor, DP-3"
              ", down, focusmonitor, DP-1"
              ", j, focusmonitor, DP-1"
              ", left, focusmonitor, DP-1"
              ", h, focusmonitor, DP-1"
              ", right, focusmonitor, DP-1"
              ", l, focusmonitor, DP-1"

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
          onDispatch = "reset";
          settings = {
            bind = map mkLuaBind (
              (map mkExecBind [
                ", l, exec, ${
                  if (osConfig.programs.uwsm.enable or false) then "uwsm stop" else lib.getExe pkgs.hyprshutdown
                }"
                ", r, exec, systemctl reboot"
                ", p, exec, systemctl poweroff"
              ])
              ++ [
                # Exit submap
                ", escape, submap, reset"
              ]
            );
          };
        };

        window = {
          settings = {
            bind = map mkLuaBind [
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
