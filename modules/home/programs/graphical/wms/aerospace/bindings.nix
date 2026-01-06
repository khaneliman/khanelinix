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
          # Window Navigation (vim-style hjkl)
          "alt-h" = "focus left";
          "alt-j" = "focus down";
          "alt-k" = "focus up";
          "alt-l" = "focus right";

          # Window Movement
          "alt-shift-h" = "move left";
          "alt-shift-j" = "move down";
          "alt-shift-k" = "move up";
          "alt-shift-l" = "move right";

          # Workspace Navigation (matching skhd workspace shortcuts)
          "cmd-ctrl-1" = "workspace 1";
          "cmd-ctrl-2" = "workspace 2";
          "cmd-ctrl-3" = "workspace 3";
          "cmd-ctrl-4" = "workspace 4";
          "cmd-ctrl-5" = "workspace 5";
          "cmd-ctrl-6" = "workspace 6";
          "cmd-ctrl-7" = "workspace 7";
          "cmd-ctrl-8" = "workspace 8";

          # Previous/Next workspace navigation (from skhd)
          "cmd-ctrl-left" = "workspace --wrap-around prev";
          "cmd-ctrl-right" = "workspace --wrap-around next";

          # Move windows to workspaces (matching skhd behavior)
          "alt-shift-1" = "move-node-to-workspace 1";
          "alt-shift-2" = "move-node-to-workspace 2";
          "alt-shift-3" = "move-node-to-workspace 3";
          "alt-shift-4" = "move-node-to-workspace 4";
          "alt-shift-5" = "move-node-to-workspace 5";
          "alt-shift-6" = "move-node-to-workspace 6";
          "alt-shift-7" = "move-node-to-workspace 7";
          "alt-shift-8" = "move-node-to-workspace 8";

          # Move windows to previous/next workspace (from skhd)
          "alt-shift-left" = "move-node-to-workspace --wrap-around prev";
          "alt-shift-right" = "move-node-to-workspace --wrap-around next";

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

          # Additional window management (from skhd)
          "alt-t" = "layout floating tiling"; # toggle float/tiling

          # Window splitting shortcuts (from skhd) - using different key to avoid conflict

          # Mirror space (from skhd yabai functionality - limited in aerospace)
          "alt-shift-x" = "layout tiles horizontal vertical";
          "alt-shift-y" = "layout tiles vertical horizontal";

          # Balance window sizes
          "alt-e" = "balance-sizes";
          "ctrl-alt-e" = "balance-sizes";

          # Additional application shortcuts (from skhd)
          "cmd-alt-ctrl-w" = "exec-and-forget open -a WezTerm";
          "cmd-alt-ctrl-o" = "exec-and-forget open -a 'Microsoft Outlook'";
          "cmd-alt-ctrl-p" = "exec-and-forget open -a 'Microsoft PowerPoint'";
        };

        # Resize mode bindings
        resize.binding = {
          # Fine-grained resize controls (matching skhd behavior)
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
