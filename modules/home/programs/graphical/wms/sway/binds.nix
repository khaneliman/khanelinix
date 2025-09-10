{
  config,
  lib,

  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    getExe'
    mkForce
    ;

  cfg = config.khanelinix.programs.graphical.wms.sway;

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
          cmd;

      # Single-argument version: mkStartCommand "command"
      withoutArgs = cmd: if (osConfig.programs.uwsm.enable or false) then "uwsm app -- ${cmd}" else cmd;
    in
    args: if lib.isString args then withoutArgs args else withArgs args;
in
{
  config = mkIf cfg.enable (
    let
      # Use the modifier from the default settings
      modifier = "Mod4";
      terminal = "kitty";

      getDateTime = getExe (
        pkgs.writeShellScriptBin "getDateTime" # bash
          ''
            echo $(date +'%Y%m%d_%H%M%S')
          ''
      );

      screenshot-path = "/home/${config.khanelinix.user.name}/Pictures/screenshots";
      browser = "${getExe config.programs.firefox.package}";
      explorer = "nautilus";
      notification_center = "${getExe' config.services.swaync.package "swaync-client"}";
      launcher = "${getExe config.programs.anyrun.package}";
      looking-glass = "looking-glass-client";
      screen-locker = "${getExe config.programs.swaylock.package}";
      # TODO: package upstream
      # window-inspector = "swayprop"; # TODO: package upstream
      screen-recorder = "record_screen";

      # screenshot commands using grim/slurp for sway
      sway_area_file = ''file="${screenshot-path}/$(${getDateTime}).png" && grim -g "$(slurp)" "$file" && notify-send "Screenshot" "Area saved to $file"'';
      sway_active_file = ''file="${screenshot-path}/$(${getDateTime}).png" && grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" "$file" && notify-send "Screenshot" "Window saved to $file"'';
      sway_screen_file = ''file="${screenshot-path}/$(${getDateTime}).png" && grim "$file" && notify-send "Screenshot" "Screen saved to $file"'';

      sway_area_swappy = ''grim -g "$(slurp)" - | swappy -f -'';
      sway_active_swappy = ''grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | swappy -f -'';
      sway_screen_swappy = ''grim - | swappy -f -'';

      sway_area_clipboard = ''grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot" "Area copied to clipboard"'';
      sway_active_clipboard = ''grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | wl-copy && notify-send "Screenshot" "Window copied to clipboard"'';
      sway_screen_clipboard = ''grim - | wl-copy && notify-send "Screenshot" "Screen copied to clipboard"'';

      # utility commands
      color_picker = "grim -g \"$(slurp -p)\" -t ppm - | ${getExe' pkgs.imagemagick "convert"} - -format '%[pixel:p{0,0}]' txt:- | tail -n1 | cut -d' ' -f4 | wl-copy && (${getExe' pkgs.imagemagick "convert"} -size 32x32 xc:$(wl-paste) /tmp/color.png && notify-send \"Color Code:\" \"$(wl-paste)\" -h \"string:bgcolor:$(wl-paste)\" --icon /tmp/color.png -u critical -t 4000)";
      cliphist = "cliphist list | sherlock | cliphist decode | wl-copy";
      walker = "walker";
      smile = "smile";
      window-inspector = "swaymsg -t get_tree | jq -r '.. | select(.focused? == true)' | notify-send 'Window Info' -t 5000";
    in
    {
      khanelinix.programs.graphical.wms.sway.settings = {
        bindsym = {
          "${modifier}+l" = "exec ${screen-locker}";
          "${modifier}+BackSpace" =
            "exec pkill -SIGUSR1 swaylock || WAYLAND_DISPLAY=wayland-1 $screen-locker";
          "${modifier}+Return" = "exec ${mkStartCommand terminal}";
          "${modifier}+Shift+q" = "kill";

          # "${modifier}+${swayCfg.left}" = "focus left";
          # "${modifier}+${swayCfg.down}" = "focus down";
          # "${modifier}+${swayCfg.up}" = "focus up";
          # "${modifier}+${swayCfg.right}" = "focus right";

          # Additional bindings - Multiple launchers like Hyprland
          # FIXME: error on load
          # "${modifier}+Space" = mkForce "exec ${sherlock}";
          "Control+Space" = "exec ${mkStartCommand launcher}";
          "Alt+Space" = "exec ${mkStartCommand walker}";
          # Dynamic slice selection - hold SHIFT to launch with background slice
        }
        // lib.optionalAttrs (osConfig.programs.uwsm.enable or false) {
          "Super_L+Shift+Space" = "exec anyrun --run-list-args \"uwsm app -s b -- \"";
          "Super_L+Shift+Control+Space" = "exec walker --app-launch-prefix \"uwsm app -s b -- \"";
          "Super_L+Shift+Return" = "exec ${mkStartCommand "${terminal} zellij"}";
          "Super_L+Shift+P" = "exec ${color_picker}";
          "${modifier}+b" = "exec ${mkStartCommand browser}";
          "Super_L+Shift+E" = "exec ${mkStartCommand explorer}";
          # Background tools - use background slice for monitoring/file management
          "${modifier}+e" = "exec ${mkStartCommand { slice = "b"; } "${terminal} yazi"}";
          "${modifier}+Control+l" = mkForce "exec ${screen-locker} --immediate";
          "${modifier}+t" = "exec ${mkStartCommand { slice = "b"; } "${terminal} btop"}";
          "${modifier}+n" = "exec ${notification_center} -t -sw";
          "${modifier}+v" = "exec ${cliphist}";
          "${modifier}+w" = "exec ${mkStartCommand looking-glass}";
          "${modifier}+i" = "exec ${window-inspector}";
          "${modifier}+period" = "exec ${mkStartCommand smile}";

          # Kill window
          "${modifier}+Q" = "kill";
          "Control+Shift+q" = "kill";

          # File screenshots
          "Print" = "exec ${sway_active_file}";
          "Shift+Print" = "exec ${sway_area_file}";
          "Super_L+Print" = "exec ${sway_screen_file}";

          # Area / Window screenshots
          "Alt+Print" = "exec ${sway_active_swappy}";
          "Alt+Control+Print" = "exec ${sway_area_swappy}";
          "Alt+Super_L+Print" = "exec ${sway_screen_swappy}";

          # Clipboard screenshots
          "Control+Print" = "exec ${sway_active_clipboard}";
          "Control+Shift+Print" = "exec ${sway_area_clipboard}";
          "Super_L+Control+Print" = "exec ${sway_screen_clipboard}";

          # Screen recording
          "${modifier}+Control+Alt+Print" = "exec ${screen-recorder} screen";
          "${modifier}+Control+Alt+Shift+Print" = "exec ${screen-recorder} area";

          # Floating toggle
          "Super_L+Alt+v" = "floating toggle";
          "${modifier}+p" = "layout tabbed";
          "${modifier}+j" = "split vertical";
          "${modifier}+f" = "fullscreen";

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
          XF86AudioMedia = "exec playerctl play-pause";
          XF86AudioPlay = "exec playerctl play-pause";
          XF86AudioStop = "exec playerctl stop";
          XF86AudioPrev = "exec playerctl previous";
          XF86AudioNext = "exec playerctl next";

          # Power management and utility
          "${modifier}+u" = ''swaymsg "output * power on"'';

          # Bar toggle (similar to Hyprland)
          "Control+Shift+b" = "exec pkill -SIGUSR1 waybar || waybar &";

          # Additional workspace navigation similar to Hyprland
          # Note: Sway doesn't support mouse_up/mouse_down bindings like Hyprland

          # Workspace bindings (generated)
          "Control+Alt+1" = "workspace number 1";
          "Control+Alt+2" = "workspace number 2";
          "Control+Alt+3" = "workspace number 3";
          "Control+Alt+4" = "workspace number 4";
          "Control+Alt+5" = "workspace number 5";
          "Control+Alt+6" = "workspace number 6";
          "Control+Alt+7" = "workspace number 7";
          "Control+Alt+8" = "workspace number 8";
          "Control+Alt+9" = "workspace number 9";
          "Control+Alt+0" = "workspace number 10";

          "Control+Alt+Shift+1" = "move container to workspace 1";
          "Control+Alt+Shift+2" = "move container to workspace 2";
          "Control+Alt+Shift+3" = "move container to workspace 3";
          "Control+Alt+Shift+4" = "move container to workspace 4";
          "Control+Alt+Shift+5" = "move container to workspace 5";
          "Control+Alt+Shift+6" = "move container to workspace 6";
          "Control+Alt+Shift+7" = "move container to workspace 7";
          "Control+Alt+Shift+8" = "move container to workspace 8";
          "Control+Alt+Shift+9" = "move container to workspace 9";
          "Control+Alt+Shift+0" = "move container to workspace 10";

          "Mod4+Shift+1" = "move container to workspace 1";
          "Mod4+Shift+2" = "move container to workspace 2";
          "Mod4+Shift+3" = "move container to workspace 3";
          "Mod4+Shift+4" = "move container to workspace 4";
          "Mod4+Shift+5" = "move container to workspace 5";
          "Mod4+Shift+6" = "move container to workspace 6";
          "Mod4+Shift+7" = "move container to workspace 7";
          "Mod4+Shift+8" = "move container to workspace 8";
          "Mod4+Shift+9" = "move container to workspace 9";
          "Mod4+Shift+0" = "move container to workspace 10";

          # Mode keybindings
          "${modifier}+s" = "mode screenshot";
          "${modifier}+x" = "mode system";
          "${modifier}+r" = "mode resize";
          "${modifier}+m" = "mode monitor";
        };

        mode = {
          screenshot = {
            bindsym = {
              "w" = "exec ${sway_active_clipboard}, mode default";
              "a" = "exec ${sway_area_clipboard}, mode default";
              "s" = "exec ${sway_screen_clipboard}, mode default";
              "Shift+w" = "exec ${sway_active_file}, mode default";
              "Shift+a" = "exec ${sway_area_file}, mode default";
              "Shift+s" = "exec ${sway_screen_file}, mode default";
              "Alt+w" = "exec ${sway_active_swappy}, mode default";
              "Alt+a" = "exec ${sway_area_swappy}, mode default";
              "Alt+s" = "exec ${sway_screen_swappy}, mode default";
              "r" = "exec record_screen screen, mode default";
              "Shift+r" = "exec record_screen area, mode default";
              "Escape" = "mode default";
              "Mod4+s" = "mode default";
            };
          };

          system = {
            bindsym = {
              "l" = "exec ${
                if (osConfig.programs.uwsm.enable or false) then "uwsm stop" else "loginctl terminate-user $USER"
              }";
              "r" = "exec systemctl reboot";
              "p" = "exec systemctl poweroff";
              "Escape" = "mode default";
              "Mod4+x" = "mode default";
            };
          };

          resize = {
            bindsym = {
              "h" = "resize shrink width 10 px or 10 ppt";
              "j" = "resize grow height 10 px or 10 ppt";
              "k" = "resize shrink height 10 px or 10 ppt";
              "l" = "resize grow width 10 px or 10 ppt";
              "left" = "resize shrink width 10 px or 10 ppt";
              "down" = "resize grow height 10 px or 10 ppt";
              "up" = "resize shrink height 10 px or 10 ppt";
              "right" = "resize grow width 10 px or 10 ppt";
              "Escape" = "mode default";
              "Mod4+r" = "mode default";
            };
          };

          monitor = {
            bindsym = {
              "h" = "focus output left";
              "j" = "focus output down";
              "k" = "focus output up";
              "l" = "focus output right";
              "left" = "focus output left";
              "down" = "focus output down";
              "up" = "focus output up";
              "right" = "focus output right";
              "Shift+h" = "move workspace to output left";
              "Shift+j" = "move workspace to output down";
              "Shift+k" = "move workspace to output up";
              "Shift+l" = "move workspace to output right";
              "Shift+left" = "move workspace to output left";
              "Shift+down" = "move workspace to output down";
              "Shift+up" = "move workspace to output up";
              "Shift+right" = "move workspace to output right";
              "Escape" = "mode default";
              "Mod4+m" = "mode default";
            };
          };
        };
      };
    }
  );
}
