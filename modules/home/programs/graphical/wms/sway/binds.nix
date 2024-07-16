{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    getExe'
    mkForce
    ;
  inherit (inputs) hyprland-contrib;

  cfg = config.${namespace}.programs.graphical.wms.sway;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        keybindings =
          let
            swayCfg = config.wayland.windowManager.sway.config;

            convert = getExe' pkgs.imagemagick "convert";
            grimblast = getExe hyprland-contrib.packages.${system}.grimblast;
            wl-copy = getExe' pkgs.wl-clipboard "wl-copy";
            wl-paste = getExe' pkgs.wl-clipboard "wl-paste";

            getDateTime = getExe (
              pkgs.writeShellScriptBin "getDateTime" # bash
                ''
                  echo $(date +'%Y%m%d_%H%M%S')
                ''
            );

            screenshot-path = "/home/${config.${namespace}.user.name}/Pictures/screenshots";
            browser = "${getExe config.programs.firefox.package}";
            explorer = "${getExe pkgs.xfce.thunar}";
            notification_center = "${getExe' config.services.swaync.package "swaync-client"}";
            launcher = "anyrun";
            looking-glass = "${getExe pkgs.looking-glass-client}";
            screen-locker = "${getExe config.programs.hyprlock.package}";
            # window-inspector = "${getExe sway-contrib.packages.${system}.hyprprop}";
            screen-recorder = "${getExe pkgs.${namespace}.record_screen}";

            # screenshot commands
            grimblast_area_file = ''file="${screenshot-path}/$(${getDateTime}).png" && ${grimblast} --freeze --notify save area "$file"'';
            grimblast_active_file = ''file="${screenshot-path}/$(${getDateTime}).png" && ${grimblast} --notify save active "$file"'';
            grimblast_screen_file = ''file="${screenshot-path}/$(${getDateTime}).png" && ${grimblast} --notify save screen "$file"'';
            grimblast_area_swappy = ''${grimblast} --freeze save area - | ${getExe pkgs.swappy} -f -'';
            grimblast_active_swappy = ''${grimblast} save active - | ${getExe pkgs.swappy} -f -'';
            grimblast_screen_swappy = ''${grimblast} save screen - | ${getExe pkgs.swappy} -f -'';
            grimblast_area_clipboard = "${grimblast} --freeze --notify copy area";
            grimblast_active_clipboard = "${grimblast} --notify copy active";
            grimblast_screen_clipboard = "${grimblast} --notify copy screen";

            # utility commands
            color_picker = "${getExe pkgs.hyprpicker} -a && (${convert} -size 32x32 xc:$(${wl-paste}) /tmp/color.png && ${getExe pkgs.libnotify} \"Color Code:\" \"$(${wl-paste})\" -h \"string:bgcolor:$(${wl-paste})\" --icon /tmp/color.png -u critical -t 4000)";
            cliphist = "${getExe pkgs.cliphist} list | anyrun --show-results-immediately true | ${getExe pkgs.cliphist} decode | ${wl-copy}";
          in
          lib.mkMerge [
            (lib.mkOptionDefault {
              "${swayCfg.modifier}+BackSpace" = "exec pkill -SIGUSR1 hyprlock || WAYLAND_DISPLAY=wayland-1 $screen-locker --immediate";
              "${swayCfg.modifier}+Return" = "exec ${swayCfg.terminal}";
              "${swayCfg.modifier}+Shift+q" = "kill";

              # "${swayCfg.modifier}+${swayCfg.left}" = "focus left";
              # "${swayCfg.modifier}+${swayCfg.down}" = "focus down";
              # "${swayCfg.modifier}+${swayCfg.up}" = "focus up";
              # "${swayCfg.modifier}+${swayCfg.right}" = "focus right";

              # Additional bindings
              # "${swayCfg.modifier}+Space" = "exec run-as-service ${launcher}";
              "Control+Space" = "exec run-as-service ${launcher}";
              "Super_L+Shift+Return" = "exec ${swayCfg.terminal} zellij";
              "Super_L+Shift+P" = "exec ${color_picker}";
              "${swayCfg.modifier}+b" = "exec ${browser}";
              "Super_L+Shift+E" = "exec ${explorer}";
              "${swayCfg.modifier}+e" = "exec ${swayCfg.terminal} yazi";
              "${swayCfg.modifier}+Control+l" = mkForce "exec ${screen-locker} --immediate";
              "${swayCfg.modifier}+t" = "exec ${swayCfg.terminal} btop";
              "${swayCfg.modifier}+n" = "exec ${notification_center} -t -sw";
              "${swayCfg.modifier}+v" = "exec ${cliphist}";
              "${swayCfg.modifier}+w" = "exec ${looking-glass}";
              # "${swayCfg.modifier}+I" = "exec ${pkgs.libnotify}/bin/notify-send ${window-inspector}";

              # Kill window
              "${swayCfg.modifier}+Q" = "kill";
              "Control+Shift+q" = "kill";

              # File screenshots
              "Print" = "exec ${grimblast_active_file}";
              "Shift+Print" = "exec ${grimblast_area_file}";
              "Super_L+Print" = "exec ${grimblast_screen_file}";

              # Area / Window screenshots
              "Alt+Print" = "exec ${grimblast_active_swappy}";
              "Alt+Control+Print" = "exec ${grimblast_area_swappy}";
              "Alt+Super_L+Print" = "exec ${grimblast_screen_swappy}";

              # Clipboard screenshots
              "Control+Print" = "exec ${grimblast_active_clipboard}";
              "Control+Shift+Print" = "exec ${grimblast_area_clipboard}";
              "Super_L+Control+Print" = "exec ${grimblast_screen_clipboard}";

              # Screen recording
              "Super_L+Control+Alt+Print" = "exec ${screen-recorder} screen";
              "Super_L+Control+Alt+Shift+Print" = "exec ${screen-recorder} area";

              # Floating toggle
              "Super_L+Alt+v" = "floating toggle";
              "${swayCfg.modifier}+p" = "layout tabbed";
              "${swayCfg.modifier}+j" = "split vertical";
              "${swayCfg.modifier}+f" = "fullscreen";

              # Focus and move windows
              "Alt+left" = "focus left";
              "Alt+right" = "focus right";
              "Alt+up" = "focus up";
              "Alt+down" = "focus down";
              "Super_L+left" = "move left";
              "Super_L+right" = "move right";
              "Super_L+up" = "move up";
              "Super_L+down" = "move down";

              "Control+Shift+h" = "resize shrink width 10px";
              "Control+Shift+l" = "resize grow width 10px";

              # Workspace switching
              "Control+Alt+right" = "workspace next";
              "Control+Alt+left" = "workspace prev";
              "Control+Alt+l" = "workspace next";
              "Control+Alt+h" = "workspace prev";

              # Moving to workspace
              "Alt+Shift+Control+right" = "move container to workspace next";
              "Alt+Shift+Control+left" = "move container to workspace prev";

              # Scratchpad
              "Super_L+Shift+grave" = "move container to scratchpad";
              "Super_L+grave" = "scratchpad show";

              # Inactive
              "Alt+Shift+grave" = "move container to workspace special:inactive";
              "Alt+grave" = "workspace special:inactive";

              # Monitor focus
              "Super_L+Alt+up" = "focus output up";
              "Super_L+Alt+down" = "focus output down";
              "Super_L+Alt+left" = "focus output left";
              "Super_L+Alt+right" = "focus output right";

              # Move workspace to monitor
              "Hyper_L+down" = "move workspace to output down";
              "Hyper_L+up" = "move workspace to output up";
              "Hyper_L+left" = "move workspace to output left";
              "Hyper_L+right" = "move workspace to output right";

              XF86AudioRaiseVolume = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%+";
              XF86AudioLowerVolume = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 2.5%-";
              XF86AudioMute = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
              XF86MonBrightnessUp = "exec light -A 5";
              XF86MonBrightnessDown = "exec light -U 5";
              XF86AudioMedia = "exec ${getExe pkgs.playerctl} play-pause";
              XF86AudioPlay = "exec ${getExe pkgs.playerctl} play-pause";
              XF86AudioStop = "exec ${getExe pkgs.playerctl} stop";
              XF86AudioPrev = "exec ${getExe pkgs.playerctl} previous";
              XF86AudioNext = "exec ${getExe pkgs.playerctl} next";
            })
            (lib.mkOptionDefault (
              builtins.listToAttrs (
                builtins.concatLists (
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
                      {
                        name = "Control+Alt+${ws}";
                        value = "workspace number ${ws}";
                      }
                      {
                        name = "Control+Alt+Super_L+${ws}";
                        value = "move container to workspace ${ws}";
                      }
                      {
                        name = "Super_L+Shift+${ws}";
                        value = "move container to workspace ${ws}";
                      }
                    ]
                  ) 10
                )
              )
            ))
          ];
      };
    };
  };
}
