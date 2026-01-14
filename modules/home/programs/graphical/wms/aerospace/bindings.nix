{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.wms.aerospace;
  sketchybar = lib.getExe (config.programs.sketchybar.finalPackage or pkgs.sketchybar);
in
{
  config = lib.mkIf cfg.enable {
    programs.aerospace.settings = {
      # Main mode key bindings
      mode = {
        main.binding = {
          # Window Navigation (vim-style hjkl and arrows)
          "alt-h" = "focus --boundaries-action wrap-around-the-workspace left";
          "alt-j" = "focus --boundaries-action wrap-around-the-workspace down";
          "alt-k" = "focus --boundaries-action wrap-around-the-workspace up";
          "alt-l" = "focus --boundaries-action wrap-around-the-workspace right";
          "alt-left" = "focus --boundaries-action wrap-around-the-workspace left";
          "alt-down" = "focus --boundaries-action wrap-around-the-workspace down";
          "alt-up" = "focus --boundaries-action wrap-around-the-workspace up";
          "alt-right" = "focus --boundaries-action wrap-around-the-workspace right";

          # Window Movement
          "alt-shift-h" = "move left";
          "alt-shift-j" = "move down";
          "alt-shift-k" = "move up";
          "alt-shift-l" = "move right";
          "alt-shift-left" = "move left";
          "alt-shift-down" = "move down";
          "alt-shift-up" = "move up";
          "alt-shift-right" = "move right";

          # Workspace Navigation
          "cmd-ctrl-1" = "workspace 1";
          "cmd-ctrl-2" = "workspace 2";
          "cmd-ctrl-3" = "workspace 3";
          "cmd-ctrl-4" = "workspace 4";
          "cmd-ctrl-5" = "workspace 5";
          "cmd-ctrl-6" = "workspace 6";
          "cmd-ctrl-7" = "workspace 7";
          "cmd-ctrl-8" = "workspace 8";

          # Previous/Next workspace navigation
          "cmd-ctrl-left" = "workspace --wrap-around prev";
          "cmd-ctrl-right" = "workspace --wrap-around next";

          # Move windows to workspaces
          "alt-shift-1" = "move-node-to-workspace 1";
          "alt-shift-2" = "move-node-to-workspace 2";
          "alt-shift-3" = "move-node-to-workspace 3";
          "alt-shift-4" = "move-node-to-workspace 4";
          "alt-shift-5" = "move-node-to-workspace 5";
          "alt-shift-6" = "move-node-to-workspace 6";
          "alt-shift-7" = "move-node-to-workspace 7";
          "alt-shift-8" = "move-node-to-workspace 8";

          # Move windows to previous/next workspace
          "alt-shift-p" = "move-node-to-workspace --wrap-around prev";
          "alt-shift-n" = "move-node-to-workspace --wrap-around next";

          # Layout Controls
          "alt-slash" = "layout tiles horizontal vertical";
          "alt-comma" = "layout accordion horizontal vertical";
          "alt-shift-space" = "layout floating tiling";

          # Split orientation
          "alt-s" = "split horizontal";
          "alt-v" = "split vertical";

          # Window Management
          "alt-f" = "fullscreen";
          "cmd-shift-f" = "fullscreen";
          "alt-shift-s" = "layout tiles horizontal vertical";

          # Application Launchers
          "cmd-enter" = "exec-and-forget ${lib.getExe pkgs.kitty} --single-instance -d ~ ";
          "cmd-shift-enter" =
            "exec-and-forget ${lib.getExe pkgs.kitty} --listen-on=unix:/tmp/kitty.sock --single-instance -d ~ -- zellij";
          "cmd-alt-ctrl-v" = "exec-and-forget open -a 'Visual Studio Code'";
          "cmd-alt-ctrl-f" = "exec-and-forget open -a 'Firefox Developer Edition'";
          # "cmd-alt-ctrl-t" = "exec-and-forget open -a WezTerm";

          # System Controls
          "ctrl-alt-cmd-r" = "reload-config";
          # "alt-shift-space" = "exec-and-forget sketchybar --bar hidden=toggle";

          # Resize mode
          "alt-r" = "mode resize";

          # Service mode
          "cmd-ctrl-s" = "mode service";

          # Additional window management
          "alt-t" = "layout floating tiling"; # toggle float/tiling

          # Window splitting shortcuts - using different key to avoid conflict

          # Resize
          "ctrl-alt-h" = "resize smart -50";
          "ctrl-alt-j" = "resize smart +50";
          "ctrl-alt-k" = "resize smart -50";
          "ctrl-alt-l" = "resize smart +50";

          # Stacking
          "ctrl-shift-h" = "join-with left";
          "ctrl-shift-j" = "join-with down";
          "ctrl-shift-k" = "join-with up";
          "ctrl-shift-l" = "join-with right";
          "ctrl-shift-n" = "focus --boundaries-action wrap-around-the-workspace dfs-next";
          "ctrl-shift-p" = "focus --boundaries-action wrap-around-the-workspace dfs-prev";
          "ctrl-shift-right" = "focus --boundaries-action wrap-around-the-workspace dfs-next";
          "ctrl-shift-left" = "focus --boundaries-action wrap-around-the-workspace dfs-prev";

          # Layouts
          "alt-shift-z" = "layout tiles horizontal vertical"; # bsp equivalent
          "alt-shift-c" = "layout accordion horizontal vertical"; # stack equivalent
          "alt-shift-x" = "layout floating tiling"; # float equivalent

          # Mirror space
          "alt-shift-y" = "layout tiles vertical horizontal";

          # Balance window sizes
          "alt-e" = "balance-sizes";
          "ctrl-alt-e" = "balance-sizes";

          # Additional application shortcuts
          "cmd-alt-ctrl-w" = "exec-and-forget open -a WezTerm";
          "cmd-alt-ctrl-o" = "exec-and-forget open -a 'Microsoft Outlook'";
          "cmd-alt-ctrl-p" = "exec-and-forget open -a 'Microsoft PowerPoint'";
        };

        # Resize mode bindings
        resize.binding = {
          # Fine-grained resize controls
          "h" = "resize smart -50";
          "j" = "resize smart +50";
          "k" = "resize smart -50";
          "l" = "resize smart +50";

          # Quick resize shortcuts
          "minus" = "resize smart -50";
          "equal" = "resize smart +50";

          # Small increments for precise control
          "shift-h" = "resize smart -10";
          "shift-j" = "resize smart +10";
          "shift-k" = "resize smart -10";
          "shift-l" = "resize smart +10";

          # Balance and equalize
          "e" = "balance-sizes";
          "0" = "balance-sizes";

          # Exit resize mode
          "enter" = "mode main";
          "esc" = "mode main";
          "q" = "mode main";
        };

        # Service mode for system controls
        service.binding = {
          # System controls
          "l" =
            "exec-and-forget osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,control down}'";
          "r" = "exec-and-forget osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'";
          "s" = "exec-and-forget osascript -e 'tell app \"loginwindow\" to «event aevtrsdn»'";

          # Service management
          "shift-r" = "reload-config";
          "cmd-r" = "exec-and-forget launchctl kickstart -k gui/$(id -u)/org.nix-community.home.aerospace";

          # Toggle sketchybar
          "b" = "exec-and-forget ${sketchybar} --bar hidden=toggle";
          "shift-b" = "exec-and-forget ${sketchybar} --exit";

          # Exit service mode
          "enter" = "mode main";
          "esc" = "mode main";
        };
      };
    };
  };
}
