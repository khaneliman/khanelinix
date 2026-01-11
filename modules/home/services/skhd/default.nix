{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.khanelinix) mkOpt;

  sketchybar = getExe (config.programs.sketchybar.finalPackage or pkgs.sketchybar);
  yabai =
    if (osConfig ? services.yabai.package) then
      getExe osConfig.services.yabai.package
    else
      getExe pkgs.yabai;

  cfg = config.khanelinix.services.skhd;
  inherit (osConfig.khanelinix.services.skhd) logPath;
in
{
  options.khanelinix.services.skhd = {
    enable = lib.mkEnableOption "skhd";
    logFile = mkOpt lib.types.str logPath "Filepath of log output";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      restart-skhd = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.skhd'';
    };

    services.skhd = {
      enable = true;
      package = pkgs.skhd;

      config = /* Bash */ ''
        # hyper (cmd + shift + alt + ctrl)
        # meh (shift + alt + ctrl)
        # Modes
        :: default : ${sketchybar} -m --set skhd icon="N" icon.color="0xff8aadf4" drawing=off
        :: window @ : ${sketchybar} -m --set skhd icon="W" icon.color="0xffa6da95" drawing=on
        :: scripts @ : ${sketchybar} -m --set skhd icon="S" icon.color="0xffed8796" drawing=on

        # Mode Shortcuts
        # NOTE: This will toggle through modes with ctrl - escape
        default, scripts < ctrl - escape ; window
        window, scripts < escape ; default
        default, window < ctrl - escape ; scripts

        # ░█▀█░█▀█░█▀█░░░█░░░█▀█░█░█░█▀█░█▀▀░█░█░█▀▀░█▀▄░█▀▀
        # ░█▀█░█▀▀░█▀▀░░░█░░░█▀█░█░█░█░█░█░░░█▀█░█▀▀░█▀▄░▀▀█
        # ░▀░▀░▀░░░▀░░░░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀
        default < cmd + shift - return : ${getExe pkgs.kitty} --listen-on=unix:/tmp/kitty.sock --single-instance -d ${config.home.homeDirectory} -- zellij
        default < cmd + alt + shift - return : ${getExe pkgs.kitty} --session nix.conf
        default < cmd - return : ${getExe pkgs.kitty} --single-instance -d ${config.home.homeDirectory}
        default < cmd + alt + ctrl - v : open /Applications/Visual\ Studio\ Code.app
        default < cmd + alt + ctrl - o : open /Applications/Microsoft\ Outlook.app
        default < cmd + alt + ctrl - p : open /Applications/Microsoft\ PowerPoint.app
        default < cmd + alt + ctrl - f : open /Applications/Firefox\ Developer\ Edition.app

        # ░█▀▀░█░█░█▀▀░▀█▀░█▀▀░█▄█
        # ░▀▀█░░█░░▀▀█░░█░░█▀▀░█░█
        # ░▀▀▀░░▀░░▀▀▀░░▀░░▀▀▀░▀░▀
        default < cmd - l : osascript -e 'tell application "System Events" to keystroke "q" using {command down,control down}';
        default < meh - r : osascript -e 'tell app "loginwindow" to «event aevtrrst»';
        default < meh - p : osascript -e 'tell app "loginwindow" to «event aevtrsdn»';

        # Reload yabai
        default < ctrl + lalt + cmd - r : bash -c launchctl kickstart -k gui/501/org.nixos.yabai
        default < shift + lalt + cmd - r : bash -c launchctl kickstart -k gui/501/org.nixos.skhd

        # Toggle sketchybar
        default < shift + lalt - space : ${sketchybar} --bar hidden=toggle
        default < shift + lalt - r : ${sketchybar} --exit

        # ░█░█░▀█▀░█▀█░█▀▄░█▀█░█░█
        # ░█▄█░░█░░█░█░█░█░█░█░█▄█
        # ░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀
        # Toggle split orientation of the selected windows node: shift + lalt - s
        default < shift + lalt - s : ${yabai} -m window --toggle split

        # Float / Unfloat window: lalt - space
        # default < lalt - space : ${yabai} -m window --toggle float; sketchybar --trigger window_focus

        # Make window zoom to fullscreen:
        # default < shift + lalt - f : ${yabai} -m window --toggle zoom-fullscreen; ${sketchybar} --trigger window_focus
        default < shift + cmd - f : ${yabai} -m query --spaces --window | grep '"type":"float"' && ${yabai} -m space --layout bsp;\
                  ${yabai} -m query --windows --window | grep '"floating":1' && ${yabai} -m window --toggle float;\
                  ${yabai} -m window --toggle zoom-fullscreen && ${sketchybar} --trigger window_focus;

        # Make window zoom to parent node:
        default < lalt - f : ${yabai} -m window --toggle zoom-parent; ${sketchybar} --trigger window_focus

        # Window Navigation (through display borders):
        default < lalt - h : ${yabai} -m window --focus west  || ${yabai} -m display --focus west
        default < lalt - j : ${yabai} -m window --focus south || ${yabai} -m display --focus south
        default < lalt - k : ${yabai} -m window --focus north || ${yabai} -m display --focus north
        default < lalt - l : ${yabai} -m window --focus east  || ${yabai} -m display --focus east

        ## Window Movement (shift + lalt - ...)
        # Moving windows in spaces:
        default < shift + lalt - h : ${yabai} -m window --warp west || $(${yabai} -m window --display west && ${sketchybar} --trigger windows_on_spaces && ${yabai} -m display --focus west && ${yabai} -m window --warp last) || ${yabai} -m window --move rel:-10:0
        default < shift + lalt - j : ${yabai} -m window --warp south || $(${yabai} -m window --display south && ${sketchybar} --trigger windows_on_spaces && ${yabai} -m display --focus south) || ${yabai} -m window --move rel:0:10
        default < shift + lalt - k : ${yabai} -m window --warp north || $(${yabai} -m window --display north && ${sketchybar} --trigger windows_on_spaces && ${yabai} -m display --focus north) || ${yabai} -m window --move rel:0:-10
        default < shift + lalt - l : ${yabai} -m window --warp east || $(${yabai} -m window --display east && ${sketchybar} --trigger windows_on_spaces && ${yabai} -m display --focus east && ${yabai} -m window --warp first) || ${yabai} -m window --move rel:10:0

        # Moving windows between spaces: shift + lalt - {1, 2, 3, 4, p, n } (Assumes 4 Spaces Max per Display)
        default < shift + lalt - 1 : SPACES=($(${yabai} -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[1] ]] \
                          && ${yabai} -m window --space $SPACES[1]

        default < shift + lalt - 2 : SPACES=($(${yabai} -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[2] ]] \
                          && ${yabai} -m window --space $SPACES[2]

        default < shift + lalt - 3 : SPACES=($(${yabai} -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[3] ]] \
                          && ${yabai} -m window --space $SPACES[3]

        default < shift + lalt - 4 : SPACES=($(${yabai} -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[4] ]] \
                  && ${yabai} -m window --space $SPACES[4]

        default < shift + lalt - left : \
        WIN_ID=$(${yabai} -m query --windows --window | jq '.id'); \
        ${yabai} -m window --swap west; \
        [[ ! $? == 0 ]] && (${yabai} -m display --focus west; \
        ${yabai} -m window last --insert east; \
        ${yabai} -m window --focus $WIN_ID; \
        ${yabai} -m window --display prev; \
        ${yabai} -m window --focus $WIN_ID);

        default < shift + lalt - right : \
        WIN_ID=$(${yabai} -m query --windows --window | jq '.id'); \
        ${yabai} -m window --swap east; \
        [[ ! $? == 0 ]] && (${yabai} -m display --focus east; \
        ${yabai} -m window first --insert west; \
        ${yabai} -m window --focus $WIN_ID; \
        ${yabai} -m window --display next; \
        ${yabai} -m window --focus $WIN_ID);

        # ░█░█░█▀█░█▀▄░█░█░█▀▀░█▀█░█▀█░█▀▀░█▀▀
        # ░█▄█░█░█░█▀▄░█▀▄░▀▀█░█▀▀░█▀█░█░░░█▀▀
        # ░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀
        # Space Navigation
        default < cmd + ctrl - left : ${yabai} -m space --focus prev
        default < cmd + ctrl - right : ${yabai} -m space --focus next

        # move to workspace by index
        default < cmd + ctrl - 1 : ${yabai} -m space --focus 1
        default < cmd + ctrl - 2 : ${yabai} -m space --focus 2
        default < cmd + ctrl - 3 : ${yabai} -m space --focus 3
        default < cmd + ctrl - 4 : ${yabai} -m space --focus 4
        default < cmd + ctrl - 5 : ${yabai} -m space --focus 5
        default < cmd + ctrl - 6 : ${yabai} -m space --focus 6
        default < cmd + ctrl - 7 : ${yabai} -m space --focus 7
        default < cmd + ctrl - 8 : ${yabai} -m space --focus 8

        # Moving windows between spaces: shift + lalt
        default < shift + lalt - 1 : ${yabai} -m window --space 1;\
                           ${sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 2 : ${yabai} -m window --space 2;\
                           ${sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 3 : ${yabai} -m window --space 3;\
                           ${sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 4 : ${yabai} -m window --space 4;\
                           ${sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 5 : ${yabai} -m window --space 5;\
                           ${sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 6 : ${yabai} -m window --space 6;\
                           ${sketchybar} --trigger windows_on_spaces
        default < shift + lalt - 7 : ${yabai} -m window --space 7;\
                           ${sketchybar} --trigger windows_on_spaces

        # Move windows to previous or next space
        default < shift + lalt - p : ${yabai} -m window --space prev; \ ${yabai} -m space --focus prev; ${sketchybar} --trigger windows_on_spaces
        default < shift + lalt - n : ${yabai} -m window --space next; ${yabai} -m space --focus next; ${sketchybar} --trigger windows_on_spaces

        # ░█░░░█▀█░█░█░█▀█░█░█░▀█▀
        # ░█░░░█▀█░░█░░█░█░█░█░░█░
        # ░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░░▀░
        # Mirror Space on X and Y Axis: shift + lalt - {x, y}
        default < shift + lalt - x : ${yabai} -m space --mirror x-axis
        default < shift + lalt - y : ${yabai} -m space --mirror y-axis

        ## Stacks (shift + ctrl - ...)
        # Add the active window to the window or stack to the {direction}: shift + ctrl - {j, k, l, ö}
        default < shift + ctrl - h : ${yabai} -m window  west --stack $(${yabai} -m query --windows --window | jq -r '.id'); ${sketchybar} --trigger window_focus
        default < shift + ctrl - j : ${yabai} -m window south --stack $(${yabai} -m query --windows --window | jq -r '.id'); ${sketchybar} --trigger window_focus
        default < shift + ctrl - k : ${yabai} -m window north --stack $(${yabai} -m query --windows --window | jq -r '.id'); ${sketchybar} --trigger window_focus
        default < shift + ctrl - l : ${yabai} -m window  east --stack $(${yabai} -m query --windows --window | jq -r '.id'); ${sketchybar} --trigger window_focus

        # Stack Navigation: shift + ctrl - {n, p}
        default < shift + ctrl - n : ${yabai} -m window --focus stack.next
        default < shift + ctrl - p : ${yabai} -m window --focus stack.prev
        default < shift + ctrl - right : ${yabai} -m window --focus stack.next
        default < shift + ctrl - left : ${yabai} -m window --focus stack.prev

        ## Resize (ctrl + lalt - ...)
        # Resize windows: ctrl + lalt - {j, k, l, ö}
        default < ctrl + lalt - h : ${yabai} -m window --resize right:-100:0 || ${yabai} -m window --resize left:-100:0
        default < ctrl + lalt - j : ${yabai} -m window --resize bottom:0:100 || ${yabai} -m window --resize top:0:100
        default < ctrl + lalt - k : ${yabai} -m window --resize bottom:0:-100 || ${yabai} -m window --resize top:0:-100
        default < ctrl + lalt - l : ${yabai} -m window --resize right:100:0 || ${yabai} -m window --resize left:100:0

        # Equalize size of windows: ctrl + lalt - e
        default < ctrl + lalt - e : ${yabai} -m space --balance

        # Enable / Disable gaps in current workspace: ctrl + lalt - g
        default < ctrl + lalt - g : ${yabai} -m space --toggle padding; ${yabai} -m space --toggle gap

        # Enable / Disable gaps in current workspace: ctrl + lalt - g
        default < ctrl + lalt - b : ${yabai} -m config window_border off
        default < shift + ctrl + lalt - b : ${yabai} -m config window_border on

        ## Insertion (shift + ctrl + lalt - ...)
        # Set insertion point for focused container: shift + ctrl + lalt - {j, k, l, ö, s}
        default < shift + ctrl + lalt - h : ${yabai} -m window --insert west
        default < shift + ctrl + lalt - j : ${yabai} -m window --insert south
        default < shift + ctrl + lalt - k : ${yabai} -m window --insert north
        default < shift + ctrl + lalt - l : ${yabai} -m window --insert east
        default < shift + ctrl + lalt - s : ${yabai} -m window --insert stack

        # Misc
        # New window in hor./ vert. splits for all applications with yabai
        default < lalt - s : ${yabai} -m window --insert east;  skhd -k "cmd - n"
        default < lalt - v : ${yabai} -m window --insert south; skhd -k "cmd - n"

        # yabai layouts
        # toggle window split type
        default < cmd - j : ${yabai} -m window --toggle split

        # float / unfloat window and center on screen
        default < lalt - t : ${yabai} -m window --toggle float; \
                  ${yabai} -m window --grid 4:4:1:1:2:2; \

        default < shift + lalt - t : ${yabai} -m window --toggle float;\
                  ${yabai} -m window --grid 20:20:1:1:18:18; \


        # toggle sticky, float and resize to picture-in-picture size
        default < lalt - p : ${yabai} -m window --toggle sticky; \
                   ${yabai} -m window --grid 4:4:2:4:4:0; \

        default < shift + lalt - z : ${yabai} -m space --layout bsp
        default < shift + lalt - x : ${yabai} -m space --layout float
        default < shift + lalt - c : ${yabai} -m space --layout stack
      '';
    };
  };
}
