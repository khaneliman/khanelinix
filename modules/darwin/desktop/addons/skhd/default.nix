{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.skhd;
in
{
  options.khanelinix.desktop.addons.skhd = with types; {
    enable = mkBoolOpt false "Whether or not to enable skhd.";
  };

  config = mkIf cfg.enable {
    services.skhd = {
      enable = true;
      package = pkgs.skhd;

      skhdConfig = with pkgs; ''
        # hyper (cmd + shift + alt + ctrl)
        # meh (shift + alt + ctrl)
        # Modes
        :: default : ${lib.getExe sketchybar} -m --set skhd icon="N" icon.color="0xff8aadf4" drawing=off
        :: window @ : ${lib.getExe sketchybar} -m --set skhd icon="W" icon.color="0xffa6da95" drawing=on
        :: scripts @ : ${lib.getExe sketchybar} -m --set skhd icon="S" icon.color="0xffed8796" drawing=on

        # Mode Shortcuts
        # NOTE: This will toggle through modes with ctrl - escape
        default, scripts < ctrl - escape ; window
        window, scripts < escape ; default
        default, window < ctrl - escape ; scripts

        # ░█▀█░█▀█░█▀█░░░█░░░█▀█░█░█░█▀█░█▀▀░█░█░█▀▀░█▀▄░█▀▀
        # ░█▀█░█▀▀░█▀▀░░░█░░░█▀█░█░█░█░█░█░░░█▀█░█▀▀░█▀▄░▀▀█
        # ░▀░▀░▀░░░▀░░░░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀
        default < cmd + shift - return : ${lib.getExe alacritty} #open over top
        default < cmd - return : ${lib.getExe pkgs.wezterm}
        default < cmd + alt + ctrl - v : open /Applications/Visual\ Studio\ Code.app
        default < cmd + alt + ctrl - o : open /Applications/Microsoft\ Outlook.app
        default < cmd + alt + ctrl - p : open /Applications/Microsoft\ PowerPoint.app
        default < cmd + alt + ctrl - f : open /Applications/Firefox\ Developer\ Edition.app
        default < cmd + alt + ctrl - t : ${lib.getExe pkgs.wezterm}

        # ░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█
        # ░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█
        # ░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀
        default < cmd - l : osascript -e 'tell application "System Events" to keystroke "q" using {command down,control down}';
        default < meh - r : osascript -e 'tell app "loginwindow" to «event aevtrrst»';
        default < meh - p : osascript -e 'tell app "loginwindow" to «event aevtrsdn»';

        # Reload yabai
        default < ctrl + lalt + cmd - r : bash -c ${lib.getExe yabai} --restart-service
        default < shift + lalt + cmd - r : bash -c ${lib.getExe skhd} --restart-service

        # Toggle sketchybar
        default < shift + lalt - space : ${lib.getExe sketchybar} --bar hidden=toggle
        default < shift + lalt - r : ${lib.getExe sketchybar} --exit

        # ░█░█░▀█▀░█▀█░█▀▄░█▀█░█░█
        # ░█▄█░░█░░█░█░█░█░█░█░█▄█
        # ░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀
        # Toggle split orientation of the selected windows node: shift + lalt - s
        default < shift + lalt - s : ${lib.getExe yabai} -m window --toggle split

        # Float / Unfloat window: lalt - space
        # default < lalt - space : ${lib.getExe yabai} -m window --toggle float; sketchybar --trigger window_focus

        # Make window zoom to fullscreen:
        # default < shift + lalt - f : ${lib.getExe yabai} -m window --toggle zoom-fullscreen; ${lib.getExe sketchybar} --trigger window_focus
        default < shift + cmd - f : ${lib.getExe yabai} -m query --spaces --window | grep '"type":"float"' && ${lib.getExe yabai} -m space --layout bsp;\
                  ${lib.getExe yabai} -m query --windows --window | grep '"floating":1' && ${lib.getExe yabai} -m window --toggle float;\
                  ${lib.getExe yabai} -m window --toggle zoom-fullscreen && ${lib.getExe sketchybar} --trigger window_focus;

        # Make window zoom to parent node:
        default < lalt - f : ${lib.getExe yabai} -m window --toggle zoom-parent; ${lib.getExe sketchybar} --trigger window_focus

        # Window Navigation (through display borders):
        default < lalt - h : ${lib.getExe yabai} -m window --focus west  || ${lib.getExe yabai} -m display --focus west
        default < lalt - j : ${lib.getExe yabai} -m window --focus south || ${lib.getExe yabai} -m display --focus south
        default < lalt - k : ${lib.getExe yabai} -m window --focus north || ${lib.getExe yabai} -m display --focus north
        default < lalt - l : ${lib.getExe yabai} -m window --focus east  || ${lib.getExe yabai} -m display --focus east

        ## Window Movement (shift + lalt - ...)
        # Moving windows in spaces:
        default < shift + lalt - h : ${lib.getExe yabai} -m window --warp west || $(${lib.getExe yabai} -m window --display west && ${lib.getExe sketchybar} --trigger windows_on_spaces && ${lib.getExe yabai} -m display --focus west && ${lib.getExe yabai} -m window --warp last) || ${lib.getExe yabai} -m window --move rel:-10:0
        default < shift + lalt - j : ${lib.getExe yabai} -m window --warp south || $(${lib.getExe yabai} -m window --display south && ${lib.getExe sketchybar} --trigger windows_on_spaces && ${lib.getExe yabai} -m display --focus south) || ${lib.getExe yabai} -m window --move rel:0:10
        default < shift + lalt - k : ${lib.getExe yabai} -m window --warp north || $(${lib.getExe yabai} -m window --display north && ${lib.getExe sketchybar} --trigger windows_on_spaces && ${lib.getExe yabai} -m display --focus north) || ${lib.getExe yabai} -m window --move rel:0:-10
        default < shift + lalt - l : ${lib.getExe yabai} -m window --warp east || $(${lib.getExe yabai} -m window --display east && ${lib.getExe sketchybar} --trigger windows_on_spaces && ${lib.getExe yabai} -m display --focus east && ${lib.getExe yabai} -m window --warp first) || ${lib.getExe yabai} -m window --move rel:10:0

        # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀
        # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀
        # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀
        # Space Navigation
        default < cmd + ctrl - left : ${lib.getExe yabai} -m space --focus prev
        default < cmd + ctrl - right : ${lib.getExe yabai} -m space --focus next

        # move to workspace by index 
        default < cmd + ctrl - 1 : ${lib.getExe yabai} -m space --focus 1
        default < cmd + ctrl - 2 : ${lib.getExe yabai} -m space --focus 2
        default < cmd + ctrl - 3 : ${lib.getExe yabai} -m space --focus 3
        default < cmd + ctrl - 4 : ${lib.getExe yabai} -m space --focus 4
        default < cmd + ctrl - 5 : ${lib.getExe yabai} -m space --focus 5
        default < cmd + ctrl - 6 : ${lib.getExe yabai} -m space --focus 6
        default < cmd + ctrl - 7 : ${lib.getExe yabai} -m space --focus 7
        default < cmd + ctrl - 8 : ${lib.getExe yabai} -m space --focus 8

        # Moving windows between spaces: shift + lalt
        default < shift + lalt - 1 : ${lib.getExe yabai} -m window --space 1;\
                           ${lib.getExe sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 2 : ${lib.getExe yabai} -m window --space 2;\
                           ${lib.getExe sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 3 : ${lib.getExe yabai} -m window --space 3;\
                           ${lib.getExe sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 4 : ${lib.getExe yabai} -m window --space 4;\
                           ${lib.getExe sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 5 : ${lib.getExe yabai} -m window --space 5;\
                           ${lib.getExe sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 6 : ${lib.getExe yabai} -m window --space 6;\
                           ${lib.getExe sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 7 : ${lib.getExe yabai} -m window --space 7;\
                           ${lib.getExe sketchybar} --trigger windows_on_spaces

        # Move windows to previous or next space
        default < shift + lalt - p : ${lib.getExe yabai} -m window --space prev; ${lib.getExe yabai} -m space --focus prev; ${lib.getExe sketchybar} --trigger windows_on_spaces
        default < shift + lalt - n : ${lib.getExe yabai} -m window --space next; ${lib.getExe yabai} -m space --focus next; ${lib.getExe sketchybar} --trigger windows_on_spaces

        # ░█░░░█▀█░█░█░█▀█░█░█░▀█▀
        # ░█░░░█▀█░░█░░█░█░█░█░░█░
        # ░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░░▀░
        # Mirror Space on X and Y Axis: shift + lalt - {x, y}
        default < shift + lalt - x : ${lib.getExe yabai} -m space --mirror x-axis
        default < shift + lalt - y : ${lib.getExe yabai} -m space --mirror y-axis

        ## Stacks (shift + ctrl - ...)
        # Add the active window to the window or stack to the {direction}: shift + ctrl - {j, k, l, ö}
        default < shift + ctrl - h : ${lib.getExe yabai} -m window  west --stack $(${lib.getExe yabai} -m query --windows --window | jq -r '.id'); ${lib.getExe sketchybar} --trigger window_focus
        default < shift + ctrl - j : ${lib.getExe yabai} -m window south --stack $(${lib.getExe yabai} -m query --windows --window | jq -r '.id'); ${lib.getExe sketchybar} --trigger window_focus
        default < shift + ctrl - k : ${lib.getExe yabai} -m window north --stack $(${lib.getExe yabai} -m query --windows --window | jq -r '.id'); ${lib.getExe sketchybar} --trigger window_focus
        default < shift + ctrl - l : ${lib.getExe yabai} -m window  east --stack $(${lib.getExe yabai} -m query --windows --window | jq -r '.id'); ${lib.getExe sketchybar} --trigger window_focus

        # Stack Navigation: shift + ctrl - {n, p}
        default < shift + ctrl - n : ${lib.getExe yabai} -m window --focus stack.next
        default < shift + ctrl - p : ${lib.getExe yabai} -m window --focus stack.prev
        default < shift + ctrl - right : ${lib.getExe yabai} -m window --focus stack.next
        default < shift + ctrl - left : ${lib.getExe yabai} -m window --focus stack.prev

        ## Resize (ctrl + lalt - ...)
        # Resize windows: ctrl + lalt - {j, k, l, ö}
        default < ctrl + lalt - h : ${lib.getExe yabai} -m window --resize right:-100:0 || ${lib.getExe yabai} -m window --resize left:-100:0
        default < ctrl + lalt - j : ${lib.getExe yabai} -m window --resize bottom:0:100 || ${lib.getExe yabai} -m window --resize top:0:100
        default < ctrl + lalt - k : ${lib.getExe yabai} -m window --resize bottom:0:-100 || ${lib.getExe yabai} -m window --resize top:0:-100
        default < ctrl + lalt - l : ${lib.getExe yabai} -m window --resize right:100:0 || ${lib.getExe yabai} -m window --resize left:100:0

        # Equalize size of windows: ctrl + lalt - e
        default < ctrl + lalt - e : ${lib.getExe yabai} -m space --balance

        # Enable / Disable gaps in current workspace: ctrl + lalt - g
        default < ctrl + lalt - g : ${lib.getExe yabai} -m space --toggle padding; ${lib.getExe yabai} -m space --toggle gap

        # Enable / Disable gaps in current workspace: ctrl + lalt - g
        default < ctrl + lalt - b : ${lib.getExe yabai} -m config window_border off
        default < shift + ctrl + lalt - b : ${lib.getExe yabai} -m config window_border on

        ## Insertion (shift + ctrl + lalt - ...)
        # Set insertion point for focused container: shift + ctrl + lalt - {j, k, l, ö, s}
        default < shift + ctrl + lalt - h : ${lib.getExe yabai} -m window --insert west
        default < shift + ctrl + lalt - j : ${lib.getExe yabai} -m window --insert south
        default < shift + ctrl + lalt - k : ${lib.getExe yabai} -m window --insert north
        default < shift + ctrl + lalt - l : ${lib.getExe yabai} -m window --insert east
        default < shift + ctrl + lalt - s : ${lib.getExe yabai} -m window --insert stack

        ## Misc
        # New window in hor./ vert. splits for all applications with yabai
        default < lalt - s : ${lib.getExe yabai} -m window --insert east;  skhd -k "cmd - n"
        default < lalt - v : ${lib.getExe yabai} -m window --insert south; skhd -k "cmd - n"

        # yabai layouts
        # toggle window split type
        default < cmd - j : ${lib.getExe yabai} -m window --toggle split

        # float / unfloat window and center on screen
        default < lalt - t : ${lib.getExe yabai} -m window --toggle float; \
                  ${lib.getExe yabai} -m window --grid 4:4:1:1:2:2; \

        default < shift + lalt - t : ${lib.getExe yabai} -m window --toggle float;\
                  ${lib.getExe yabai} -m window --grid 20:20:1:1:18:18; \


        # toggle sticky, float and resize to picture-in-picture size
        default < lalt - p : ${lib.getExe yabai} -m window --toggle sticky; \
                   ${lib.getExe yabai} -m window --grid 4:4:2:4:4:0; \

        default < shift + lalt - z : ${lib.getExe yabai} -m space --layout bsp
        default < shift + lalt - x : ${lib.getExe yabai} -m space --layout float
        default < shift + lalt - c : ${lib.getExe yabai} -m space --layout stack
      '';
    };
  };
}
