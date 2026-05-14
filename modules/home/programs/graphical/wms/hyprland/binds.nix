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
    floatandpin = _: ''
      function()
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
        hl.dispatch(hl.dsp.window.pin())
      end
    '';
  };

  mkDispatcher =
    dispatcher: args:
    if dispatcher == "exec" then
      mkExecDispatcher args
    else
      dispatcherMap.${dispatcher} or (mkExecRawDispatcher dispatcher) args;

  mkBind =
    {
      mods,
      key,
      dispatcher,
      args ? "",
      wrap ? true,
    }:
    {
      inherit
        mods
        key
        dispatcher
        args
        wrap
        ;
    };

  mkExecBind =
    mods: key: args:
    mkBind {
      inherit mods key;
      dispatcher = "exec";
      inherit args;
    };

  mkExecBindRaw =
    mods: key: args:
    mkBind {
      inherit mods key;
      dispatcher = "exec";
      inherit args;
      wrap = false;
    };

  mkLuaBindWith =
    opts: bind:
    let
      resolvedBind =
        if lib.isString bind then
          let
            parts = map lib.trim (lib.splitString "," (replaceCommandVars bind));
            mods = builtins.elemAt parts 0;
            key = builtins.elemAt parts 1;
            dispatcher = builtins.elemAt parts 2;
            args = lib.concatStringsSep "," (lib.drop 3 parts);
          in
          {
            inherit
              mods
              key
              dispatcher
              args
              ;
          }
        else
          bind;
      mods = replaceCommandVars (resolvedBind.mods or "");
      key = resolvedBind.key or "";
      dispatcher = resolvedBind.dispatcher or "";
      args = resolvedBind.args or "";
      wrap = if resolvedBind ? wrap then resolvedBind.wrap else true;
      expandedArgs =
        if dispatcher == "exec" && wrap then
          mkStartCommand (replaceCommandVars args)
        else
          replaceCommandVars args;
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
        (lua (mkDispatcher dispatcher expandedArgs))
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
              lib.optional (count > 0) (mkExecBind "CTRL" "SPACE" "$($launcher)")
              ++ lib.optional (count > 1) (mkExecBind "ALT" "SPACE" "$($launcher-alt)")
              ++ lib.optional (count > 2) (mkExecBind "$mainMod" "SPACE" "$($launcher-backup)");

            # App launch binds
            appBinds = [
              # Interactive applications (app-graphical.slice)
              (mkExecBind "$mainMod" "RETURN" "$term")
              (mkExecBind "SUPER_SHIFT" "RETURN" "$term zellij")
              (mkExecBind "SUPER_SHIFT" "P" "$color_picker")
              (mkExecBind "$mainMod" "B" "$browser")
              (mkExecBind "SUPER_SHIFT" "E" "$explorer")
              (mkExecBind "$mainMod" "L" "$screen-locker --immediate")
              (mkExecBind "$mainMod" "N" "$notification_center -t -sw")
              (mkExecBind "$mainMod" "V" "$cliphist")
              # TODO: handle when you need to specify port manually `-p 5901`
              (mkExecBind "$mainMod" "W" "$looking-glass")
            ];

            # Background tools binds (background-graphical.slice)
            backgroundBinds = [
              (mkExecBindRaw "$mainMod" "E" "${mkStartCommand { slice = "b"; } "$term yazi"}")
              (mkExecBindRaw "$mainMod" "T" "${mkStartCommand { slice = "b"; } "$term btop"}")
            ];

            # System binds (non-exec) - keeping most used shortcuts
            systemBinds = [
              (mkBind {
                mods = "$mainMod";
                key = "Q";
                dispatcher = "killactive";
              })
              (mkBind {
                mods = "CTRL_SHIFT";
                key = "Q";
                dispatcher = "killactive";
              })
              (mkBind {
                mods = "$mainMod";
                key = "F";
                dispatcher = "fullscreen";
              }) # Keep F for fullscreen as it's commonly used
            ];

            # Screenshot binds - keep Print key shortcuts for compatibility
            screenshotBinds = [
              # Quick screenshot shortcuts (original binds)
              (mkExecBind "" "Print" "$screenshot_active_clipboard")
              (mkExecBind "SHIFT" "Print" "$screenshot_area_clipboard")
              (mkExecBind "SUPER" "Print" "$screenshot_screen_clipboard")
            ];

            # Window movement binds - keeping basic movement
            movementBinds = [
              # Window Focus
              (mkBind {
                mods = "ALT";
                key = "left";
                dispatcher = "movefocus";
                args = "l";
              })
              (mkBind {
                mods = "ALT";
                key = "right";
                dispatcher = "movefocus";
                args = "r";
              })
              (mkBind {
                mods = "ALT";
                key = "up";
                dispatcher = "movefocus";
                args = "u";
              })
              (mkBind {
                mods = "ALT";
                key = "down";
                dispatcher = "movefocus";
                args = "d";
              })
              # Move window
              (mkBind {
                mods = "SUPER";
                key = "left";
                dispatcher = "movewindow";
                args = "l";
              })
              (mkBind {
                mods = "SUPER";
                key = "right";
                dispatcher = "movewindow";
                args = "r";
              })
              (mkBind {
                mods = "SUPER";
                key = "up";
                dispatcher = "movewindow";
                args = "u";
              })
              (mkBind {
                mods = "SUPER";
                key = "down";
                dispatcher = "movewindow";
                args = "d";
              })
            ];

            # Workspace management binds
            workspaceBinds = [
              # Swipe through existing workspaces with CTRL_ALT + left / right
              (mkBind {
                mods = "CTRL_ALT";
                key = "right";
                dispatcher = "workspace";
                args = "+1";
              })
              (mkBind {
                mods = "CTRL_ALT";
                key = "l";
                dispatcher = "workspace";
                args = "+1";
              })
              (mkBind {
                mods = "CTRL_ALT";
                key = "left";
                dispatcher = "workspace";
                args = "-1";
              })
              (mkBind {
                mods = "CTRL_ALT";
                key = "h";
                dispatcher = "workspace";
                args = "-1";
              })
              # Scroll through existing workspaces with CTRL_ALT + scroll
              (mkBind {
                mods = "CTRL_ALT";
                key = "mouse_down";
                dispatcher = "workspace";
                args = "e+1";
              })
              (mkBind {
                mods = "CTRL_ALT";
                key = "mouse_up";
                dispatcher = "workspace";
                args = "e-1";
              })
              # Move to workspace left/right
              (mkBind {
                mods = "$ALT-HYPER";
                key = "right";
                dispatcher = "movetoworkspace";
                args = "+1";
              })
              (mkBind {
                mods = "$ALT-HYPER";
                key = "l";
                dispatcher = "movetoworkspace";
                args = "+1";
              })
              (mkBind {
                mods = "$ALT-HYPER";
                key = "left";
                dispatcher = "movetoworkspace";
                args = "-1";
              })
              (mkBind {
                mods = "$ALT-HYPER";
                key = "h";
                dispatcher = "movetoworkspace";
                args = "-1";
              })
              # MOVING silently LEFT/RIGHT
              (mkBind {
                mods = "SUPER_SHIFT";
                key = "right";
                dispatcher = "movetoworkspacesilent";
                args = "+1";
              })
              (mkBind {
                mods = "SUPER_SHIFT";
                key = "l";
                dispatcher = "movetoworkspacesilent";
                args = "+1";
              })
              (mkBind {
                mods = "SUPER_SHIFT";
                key = "left";
                dispatcher = "movetoworkspacesilent";
                args = "-1";
              })
              (mkBind {
                mods = "SUPER_SHIFT";
                key = "h";
                dispatcher = "movetoworkspacesilent";
                args = "-1";
              })
            ];

            # Monitor management binds
            monitorBinds = [
              # Enter monitor submap
              (mkBind {
                mods = "$mainMod";
                key = "M";
                dispatcher = "submap";
                args = "monitor";
              })
            ];

            # Special workspace binds
            specialBinds = [
              # Scratchpad
              (mkBind {
                mods = "SUPER_SHIFT";
                key = "grave";
                dispatcher = "movetoworkspace";
                args = "special:scratchpad";
              })
              (mkBind {
                mods = "SUPER";
                key = "grave";
                dispatcher = "togglespecialworkspace";
                args = "scratchpad";
              })
              # Inactive
              (mkBind {
                mods = "ALT_SHIFT";
                key = "grave";
                dispatcher = "movetoworkspace";
                args = "special:inactive";
              })
              (mkBind {
                mods = "ALT";
                key = "grave";
                dispatcher = "togglespecialworkspace";
                args = "inactive";
              })
            ];

            # System and window submap triggers
            submapTriggerBinds = [
              (mkBind {
                mods = "$mainMod";
                key = "S";
                dispatcher = "submap";
                args = "screenshot";
              })
              (mkBind {
                mods = "$mainMod";
                key = "X";
                dispatcher = "submap";
                args = "system";
              })
              (mkBind {
                mods = "$mainMod";
                key = "W";
                dispatcher = "submap";
                args = "window";
              })
            ];

            lockedBinds = [
              (mkExecBind "$mainMod" "BackSpace"
                "pkill -SIGUSR1 hyprlock || WAYLAND_DISPLAY=wayland-1 $screen-locker"
              )
              (mkExecBind "" "XF86AudioRaiseVolume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%+")
              (mkExecBind "" "XF86AudioLowerVolume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%-")
              (mkExecBind "" "XF86AudioMute" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
              (mkExecBind "" "XF86MonBrightnessUp" "light -A 5")
              (mkExecBind "" "XF86MonBrightnessDown" "light -U 5")
              (mkExecBind "" "XF86AudioMedia" "playerctl play-pause")
              (mkExecBind "" "XF86AudioPlay" "playerctl play-pause")
              (mkExecBind "" "XF86AudioStop" "playerctl stop")
              (mkExecBind "" "XF86AudioPrev" "playerctl previous")
              (mkExecBind "" "XF86AudioNext" "playerctl next")
            ];

            mouseBinds = [
              (mkBind {
                mods = "$mainMod";
                key = "mouse:272";
                dispatcher = "movewindow";
              })
              (mkBind {
                mods = "CTRL_SHIFT";
                key = "mouse:272";
                dispatcher = "movewindow";
              })
              (mkBind {
                mods = "$mainMod";
                key = "mouse:273";
                dispatcher = "resizewindow";
              })
              (mkBind {
                mods = "CTRL_SHIFT";
                key = "mouse:273";
                dispatcher = "resizewindow";
              })
            ];
          in
          (map mkLuaBind (
            (launcherBinds ++ appBinds ++ screenshotBinds)
            ++ backgroundBinds
            ++ systemBinds
            ++ movementBinds
            ++ workspaceBinds
            ++ monitorBinds
            ++ specialBinds
            ++ submapTriggerBinds
            ++ [
              (mkExecBind "$mainMod" "I" "notify-send \"$($window-inspector)\"")
              (mkExecBind "$mainMod" "PERIOD" "smile")
              (mkExecBind "$CTRL_SHIFT" "B" "killall -SIGUSR1 $bar")
            ]
            ++
              lib.optional (lib.elem pkgs.hyprlandPlugins.hyprexpo config.wayland.windowManager.hyprland.plugins)
                (mkBind {
                  mods = "SUPER";
                  key = "Escape";
                  dispatcher = "hyprexpo:expo";
                  args = "toggle";
                })
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
                  (mkBind {
                    mods = "$CTRL_ALT";
                    key = "${ws}";
                    dispatcher = "workspace";
                    args = toString (x + 1);
                  })
                  (mkBind {
                    mods = "$CTRL_ALT_SUPER";
                    key = "${ws}";
                    dispatcher = "movetoworkspace";
                    args = toString (x + 1);
                  })
                  (mkBind {
                    mods = "$SUPER_SHIFT";
                    key = "${ws}";
                    dispatcher = "movetoworkspacesilent";
                    args = toString (x + 1);
                  })
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
              [
                # Clipboard screenshots
                (mkExecBind "" "w" "$screenshot_active_clipboard") # current window
                (mkExecBind "" "a" "$screenshot_area_clipboard") # area selection
                (mkExecBind "" "s" "$screenshot_screen_clipboard") # full screen

                # File screenshots
                (mkExecBind "SHIFT" "w" "$screenshot_active_file")
                (mkExecBind "SHIFT" "a" "$screenshot_area_file")
                (mkExecBind "SHIFT" "s" "$screenshot_screen_file")

                # Annotated screenshots
                (mkExecBind "ALT" "w" "$screenshot_active_annotate")
                (mkExecBind "ALT" "a" "$screenshot_area_annotate")
                (mkExecBind "ALT" "s" "$screenshot_screen_annotate")

                # Screen recording
                (mkExecBind "" "r" "$screen-recorder screen")
                (mkExecBind "SHIFT" "r" "$screen-recorder area")
              ]
              ++ [
                # Exit submap
                (mkBind {
                  mods = "";
                  key = "escape";
                  dispatcher = "submap";
                  args = "reset";
                })
              ]
            );
          };
        };

        monitor = {
          settings = {
            bind = map mkLuaBind [
              # Focus monitor
              (mkBind {
                mods = "";
                key = "up";
                dispatcher = "focusmonitor";
                args = "u";
              })
              (mkBind {
                mods = "";
                key = "k";
                dispatcher = "focusmonitor";
                args = "u";
              })
              (mkBind {
                mods = "";
                key = "down";
                dispatcher = "focusmonitor";
                args = "d";
              })
              (mkBind {
                mods = "";
                key = "j";
                dispatcher = "focusmonitor";
                args = "d";
              })
              (mkBind {
                mods = "";
                key = "left";
                dispatcher = "focusmonitor";
                args = "l";
              })
              (mkBind {
                mods = "";
                key = "h";
                dispatcher = "focusmonitor";
                args = "l";
              })
              (mkBind {
                mods = "";
                key = "right";
                dispatcher = "focusmonitor";
                args = "r";
              })
              (mkBind {
                mods = "";
                key = "l";
                dispatcher = "focusmonitor";
                args = "r";
              })

              # Move workspace to monitor
              (mkBind {
                mods = "SHIFT";
                key = "up";
                dispatcher = "movecurrentworkspacetomonitor";
                args = "u";
              })
              (mkBind {
                mods = "SHIFT";
                key = "k";
                dispatcher = "movecurrentworkspacetomonitor";
                args = "u";
              })
              (mkBind {
                mods = "SHIFT";
                key = "down";
                dispatcher = "movecurrentworkspacetomonitor";
                args = "d";
              })
              (mkBind {
                mods = "SHIFT";
                key = "j";
                dispatcher = "movecurrentworkspacetomonitor";
                args = "d";
              })
              (mkBind {
                mods = "SHIFT";
                key = "left";
                dispatcher = "movecurrentworkspacetomonitor";
                args = "l";
              })
              (mkBind {
                mods = "SHIFT";
                key = "h";
                dispatcher = "movecurrentworkspacetomonitor";
                args = "l";
              })
              (mkBind {
                mods = "SHIFT";
                key = "right";
                dispatcher = "movecurrentworkspacetomonitor";
                args = "r";
              })
              (mkBind {
                mods = "SHIFT";
                key = "l";
                dispatcher = "movecurrentworkspacetomonitor";
                args = "r";
              })

              # Exit submap
              (mkBind {
                mods = "";
                key = "escape";
                dispatcher = "submap";
                args = "reset";
              })
              (mkBind {
                mods = "SUPER";
                key = "M";
                dispatcher = "submap";
                args = "reset";
              })
            ];
          };
        };

        system = {
          onDispatch = "reset";
          settings = {
            bind = map mkLuaBind (
              [
                (mkExecBind "" "l" (
                  if (osConfig.programs.uwsm.enable or false) then "uwsm stop" else lib.getExe pkgs.hyprshutdown
                ))
                (mkExecBind "" "r" "systemctl reboot")
                (mkExecBind "" "p" "systemctl poweroff")
              ]
              ++ [
                # Exit submap
                (mkBind {
                  mods = "";
                  key = "escape";
                  dispatcher = "submap";
                  args = "reset";
                })
              ]
            );
          };
        };

        window = {
          settings = {
            bind = map mkLuaBind [
              # Window operations
              (mkBind {
                mods = "";
                key = "f";
                dispatcher = "fullscreen";
              })
              (mkBind {
                mods = "";
                key = "v";
                dispatcher = "togglefloating";
              })
              (mkBind {
                mods = "";
                key = "i";
                dispatcher = "floatandpin";
              })
              (mkBind {
                mods = "";
                key = "p";
                dispatcher = "pseudo";
              })
              (mkBind {
                mods = "";
                key = "j";
                dispatcher = "togglesplit";
              })
              (mkBind {
                mods = "";
                key = "k";
                dispatcher = "swapsplit";
              })

              # Resize operations
              (mkBind {
                mods = "";
                key = "h";
                dispatcher = "resizeactive";
                args = "-10% 0";
              })
              (mkBind {
                mods = "";
                key = "l";
                dispatcher = "resizeactive";
                args = "10% 0";
              })
              (mkBind {
                mods = "SHIFT";
                key = "h";
                dispatcher = "resizeactive";
                args = "0 -10%";
              })
              (mkBind {
                mods = "SHIFT";
                key = "l";
                dispatcher = "resizeactive";
                args = "0 10%";
              })

              # Exit submap
              (mkBind {
                mods = "";
                key = "escape";
                dispatcher = "submap";
                args = "reset";
              })
              (mkBind {
                mods = "SUPER";
                key = "R";
                dispatcher = "submap";
                args = "reset";
              })
            ];
          };
        };
      };
    };
  };
}
