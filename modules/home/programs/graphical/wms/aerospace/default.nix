{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) mkOpt;
  cfg = config.khanelinix.programs.graphical.wms.aerospace;

  sketchybar = lib.getExe (config.programs.sketchybar.finalPackage or pkgs.sketchybar);
in
{
  options.khanelinix.programs.graphical.wms.aerospace = {
    enable = lib.mkEnableOption "aerospace";
    debug = lib.mkEnableOption "debug output";
    logFile =
      mkOpt lib.types.str "${config.khanelinix.user.home}/Library/Logs/aerospace.log"
        "Filepath of log output";
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases = {
      restart-aerospace = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.aerospace'';
    };

    programs.aerospace = {
      enable = true;
      package = pkgs.aerospace;

      launchd.enable = true;

      settings = {
        # Core Settings - matching yabai preferences
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;
        accordion-padding = 30;
        default-root-container-layout = "tiles";
        default-root-container-orientation = "auto";
        key-mapping.preset = "qwerty";

        # Gaps configuration (matching yabai: top=20, others=10)
        gaps = {
          inner = {
            horizontal = 10;
            vertical = 10;
          };
          outer = {
            left = 10;
            bottom = 10;
            top = 20;
            right = 10;
          };
        };

        # Integration hooks
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
        exec-on-workspace-change = [
          "/bin/bash"
          "-c"
          "${sketchybar} --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
        ];

        # Startup commands
        after-startup-command = [
          "exec-and-forget open ${pkgs.raycast}/Applications/Raycast.app"
          "exec-and-forget open -a Amphetamine"
          # Ensure numbered workspaces 1-8 are created
          "workspace 1"
          "workspace 2"
          "workspace 3"
          "workspace 4"
          "workspace 5"
          "workspace 6"
          "workspace 7"
          "workspace 8"
          "workspace 1" # Go back to workspace 1
        ];

        # Window detection rules for workspace assignment
        on-window-detected = [
          # Browsers -> workspace 1 (main)
          {
            "if" = {
              app-id = "org.mozilla.firefoxdeveloperedition";
            };
            run = "move-node-to-workspace 1";
          }
          {
            "if" = {
              app-id = "org.mozilla.firefox";
            };
            run = "move-node-to-workspace 1";
          }
          {
            "if" = {
              app-id = "com.google.Chrome";
            };
            run = "move-node-to-workspace 1";
          }
          {
            "if" = {
              app-id = "com.apple.Safari";
            };
            run = "move-node-to-workspace 1";
          }
          # Communication apps -> workspace 2 (comms)
          {
            "if" = {
              app-id = "com.microsoft.teams2";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.apple.mail";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.apple.MobileSMS";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.readdle.smartemail-Mac";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.hnc.Discord";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "org.mozilla.thunderbird";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.facebook.archon.developerID";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.facebook.messenger.desktop";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "com.tinyspeck.slackmacgap";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "ru.keepcoder.Telegram";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "im.riot.app";
            };
            run = "move-node-to-workspace 2";
          }
          {
            "if" = {
              app-id = "dev.vencord.Vesktop";
            };
            run = "move-node-to-workspace 2";
          }
          # Development tools -> workspace 3 (code)
          {
            "if" = {
              app-id = "io.qt.QtCreator";
            };
            run = "move-node-to-workspace 3";
          }
          {
            "if" = {
              app-id = "com.microsoft.VSCode";
            };
            run = "move-node-to-workspace 3";
          }
          {
            "if" = {
              app-id = "com.microsoft.visual-studio";
            };
            run = "move-node-to-workspace 3";
          }
          {
            "if" = {
              app-id = "com.apple.dt.Xcode";
            };
            run = "move-node-to-workspace 3";
          }
          # Git tools -> workspace 4 (ref)
          {
            "if" = {
              app-id = "com.github.GitHubClient";
            };
            run = "move-node-to-workspace 4";
          }
          {
            "if" = {
              app-id = "com.axosoft.gitkraken";
            };
            run = "move-node-to-workspace 4";
          }
          # Productivity apps -> workspace 5 (productivity)
          {
            "if" = {
              app-id = "com.apple.Notes";
            };
            run = "move-node-to-workspace 5";
          }
          {
            "if" = {
              app-id = "com.apple.reminders";
            };
            run = "move-node-to-workspace 5";
          }
          {
            "if" = {
              app-id = "com.apple.iCal";
            };
            run = "move-node-to-workspace 5";
          }
          {
            "if" = {
              app-id = "com.flexibits.fantastical2.mac";
            };
            run = "move-node-to-workspace 5";
          }
          # Media apps -> workspace 6 (media)
          {
            "if" = {
              app-id = "com.apple.Music";
            };
            run = "move-node-to-workspace 6";
          }
          {
            "if" = {
              app-id = "tv.plex.desktop";
            };
            run = "move-node-to-workspace 6";
          }
          {
            "if" = {
              app-id = "com.spotify.client";
            };
            run = "move-node-to-workspace 6";
          }
          {
            "if" = {
              app-id = "org.videolan.vlc";
            };
            run = "move-node-to-workspace 6";
          }
          # VMs -> workspace 7 (vm)
          {
            "if" = {
              app-id = "com.utmapp.UTM";
            };
            run = "move-node-to-workspace 7";
          }
          {
            "if" = {
              app-id = "com.parallels.desktop.console";
            };
            run = "move-node-to-workspace 7";
          }
        ];

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

            # Window Management
            "alt-f" = "fullscreen";
            "cmd-shift-f" = "fullscreen";
            "alt-shift-s" = "layout tiles horizontal vertical";

            # Application Launchers
            "cmd-enter" = "exec-and-forget ${lib.getExe pkgs.kitty} --single-instance -d ~";
            "cmd-shift-enter" =
              "exec-and-forget ${lib.getExe pkgs.kitty} --listen-on=unix:/tmp/kitty.sock --single-instance -d ~ -- zellij
";
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
  };
}
