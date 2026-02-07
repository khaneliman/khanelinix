{
  config,
  lib,
  pkgs,
  options,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.wms.niri;
  niriAvailable = options ? programs.niri;

  inherit (config.khanelinix.programs.graphical) launchers;

  # ── NOTE: ───────────────────────────────────────────────────
  # ╭──────────────────────────────────────────────────────────╮
  # │                   Valid modifiers are:                   │
  # ╰──────────────────────────────────────────────────────────╯
  # ╭──────────────────────────────────────────────────────────╮
  # │ Ctrl or Control;                                         │
  # │ Shift;                                                   │
  # │ Alt;                                                     │
  # │ Super or Win;                                            │
  # │ ISO_Level3_Shift or Mod5—this is the AltGr key on        │
  # │ certain layouts;                                         │
  # │ ISO_Level5_Shift: can be used with an xkb lv5 option     │
  # │ like lv5:caps_switch;                                    │
  # │ Mod.                                                     │
  # ╰──────────────────────────────────────────────────────────╯
  # ╭──────────────────────────────────────────────────────────╮
  # │  Mod is a special modifier that is equal to Super when   │
  # │  running niri on a TTY, and to Alt when running niri as  │
  # │ a nested winit window. This way, you can test niri in a  │
  # │ window without causing too many conflicts with the host  │
  # │ compositor's key bindings. For this reason, most of the  │
  # │            default keys use the Mod modifier.            │
  # ╰──────────────────────────────────────────────────────────╯

in
{
  config = mkIf cfg.enable (
    lib.optionalAttrs niriAvailable {
      programs.niri.settings.binds =
        let
          enabledLaunchers =
            (lib.optionals launchers.vicinae.enable [
              [
                "vicinae"
                "open"
              ]
            ])
            ++ (lib.optionals launchers.anyrun.enable [ [ "anyrun" ] ])
            ++ (lib.optionals launchers.walker.enable [ [ "walker" ] ])
            ++ (lib.optionals launchers.sherlock.enable [ [ "sherlock" ] ])
            ++ (lib.optionals launchers.rofi.enable [
              [
                "rofi"
                "-show"
                "drun"
              ]
            ]);

          launcherCount = builtins.length enabledLaunchers;

          defaultLauncher = if launcherCount > 0 then builtins.elemAt enabledLaunchers 0 else null;

          altLauncher = if launcherCount > 1 then builtins.elemAt enabledLaunchers 1 else null;

          backupLauncher = if launcherCount > 2 then builtins.elemAt enabledLaunchers 2 else null;

          enabledDmenuLaunchers = lib.flatten [
            (lib.optional launchers.vicinae.enable "vicinae dmenu")
            (lib.optional launchers.anyrun.enable "anyrun --show-results-immediately true")
            (lib.optional launchers.walker.enable "walker --stream")
            (lib.optional launchers.sherlock.enable "sherlock")
            (lib.optional launchers.rofi.enable "rofi -dmenu")
          ];

          dmenuLauncher =
            if builtins.length enabledDmenuLaunchers > 0 then
              builtins.head enabledDmenuLaunchers
            else
              "rofi -dmenu";

          wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
          wlPaste = lib.getExe' pkgs.wl-clipboard "wl-paste";
          magick = lib.getExe' pkgs.imagemagick "magick";

          lockCommand =
            if config.khanelinix.programs.graphical.screenlockers.swaylock.enable then
              [ (lib.getExe config.programs.swaylock.package) ]
            else
              [
                "loginctl"
                "lock-session"
              ];

          browserCommand = lib.getExe config.programs.firefox.package;
          explorerCommand = "nautilus";
          notificationCommand = "swaync-client -t -sw";
          lookingGlassCommand = "looking-glass-client";

          cliphistCommand = "cliphist list | ${dmenuLauncher} | cliphist decode | ${wlCopy}";

          colorPickerCommand = "hyprpicker -a && (${magick} convert -size 32x32 xc:$(${wlPaste}) /tmp/color.png && notify-send \"Color Code:\" \"$(${wlPaste})\" -h \"string:bgcolor:$(${wlPaste})\" --icon /tmp/color.png -u critical -t 4000)";

          hyprpickerEnabled = lib.elem pkgs.hyprpicker config.home.packages;

          workspaceDigitBinds = builtins.listToAttrs (
            map (
              ws:
              let
                key = if ws == 10 then "0" else toString ws;
              in
              {
                name = "Ctrl+Alt+${key}";
                value.action.focus-workspace = ws;
              }
            ) (lib.range 1 10)
          );

          workspaceMoveBinds = builtins.listToAttrs (
            map (
              ws:
              let
                key = if ws == 10 then "0" else toString ws;
              in
              {
                name = "Ctrl+Alt+Super+${key}";
                value.action.move-column-to-workspace = ws;
              }
            ) (lib.range 1 10)
          );

          workspaceSilentMoveBinds = builtins.listToAttrs (
            map (
              ws:
              let
                key = if ws == 10 then "0" else toString ws;
              in
              {
                name = "Mod+Shift+${key}";
                value.action.move-column-to-workspace = ws;
              }
            ) (lib.range 1 10)
          );

          launcherBinds =
            lib.optionalAttrs (defaultLauncher != null) {
              "Ctrl+Space" = {
                action.spawn = defaultLauncher;
                allow-inhibiting = false;
              };
            }
            // lib.optionalAttrs (altLauncher != null) {
              "Alt+Space".action.spawn = altLauncher;
            }
            // lib.optionalAttrs (backupLauncher != null) {
              "Mod+Space".action.spawn = backupLauncher;
            };

          pickerBind = lib.optionalAttrs hyprpickerEnabled {
            "Mod+Shift+P".action.spawn = colorPickerCommand;
          };
        in
        launcherBinds
        // pickerBind
        // {
          "Mod+Return".action.spawn = "kitty";
          "Mod+Shift+Return".action.spawn = "kitty zellij";
          "Mod+B".action.spawn = browserCommand;
          "Mod+Shift+E".action.spawn = explorerCommand;
          "Mod+L".action.spawn = lockCommand;
          "Mod+N".action.spawn = notificationCommand;
          "Mod+V".action.spawn = cliphistCommand;
          "Mod+W".action.spawn = lookingGlassCommand;

          "Mod+E".action.spawn = "kitty yazi";
          "Mod+T".action.spawn = "kitty btop";

          "Mod+Q".action.close-window = [ ];
          "Ctrl+Shift+Q".action.close-window = [ ];

          # Focus bindings (matching Hyprland ALT pattern, adapted for Niri's scrolling)
          "Alt+Left".action.focus-column-left = [ ];
          "Alt+Right".action.focus-column-right = [ ];
          "Alt+H".action.focus-column-left = [ ];
          "Alt+L".action.focus-column-right = [ ];

          # Workspace focus bindings
          "Ctrl+Alt+Down".action.focus-workspace-down = [ ];
          "Ctrl+Alt+Up".action.focus-workspace-up = [ ];
          "Ctrl+Alt+J".action.focus-workspace-down = [ ];
          "Ctrl+Alt+K".action.focus-workspace-up = [ ];

          # Move window bindings (using Mod+Shift to avoid conflict with Mod+L lock)
          "Mod+Left".action.move-column-left = [ ];
          "Mod+Right".action.move-column-right = [ ];
          "Mod+Down".action.move-column-to-workspace-down = [ ];
          "Mod+Up".action.move-column-to-workspace-up = [ ];

          "Mod+Shift+H".action.move-column-left = [ ];
          "Mod+Shift+L".action.move-column-right = [ ];
          "Mod+Shift+J".action.move-column-to-workspace-down = [ ];
          "Mod+Shift+K".action.move-column-to-workspace-up = [ ];

          # Wheel scrolling
          "Mod+WheelScrollDown" = {
            cooldown-ms = 150;
            action.focus-workspace-down = [ ];
          };
          "Mod+WheelScrollUp" = {
            cooldown-ms = 150;
            action.focus-workspace-up = [ ];
          };
          "Mod+WheelScrollRight".action.focus-column-right = [ ];
          "Mod+WheelScrollLeft".action.focus-column-left = [ ];

          "Mod+Ctrl+Shift+K".action.move-column-to-monitor-up = [ ];
          "Mod+Ctrl+Shift+J".action.move-column-to-monitor-down = [ ];

          "Mod+Page_Down".action.focus-workspace-down = [ ];
          "Mod+Page_Up".action.focus-workspace-up = [ ];

          "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [ ];
          "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [ ];

          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;

          "Mod+Ctrl+1".action.move-column-to-workspace = 1;
          "Mod+Ctrl+2".action.move-column-to-workspace = 2;
          "Mod+Ctrl+3".action.move-column-to-workspace = 3;
          "Mod+Ctrl+4".action.move-column-to-workspace = 4;
          "Mod+Ctrl+5".action.move-column-to-workspace = 5;

          "Mod+Comma".action.consume-or-expel-window-left = [ ];
          "Mod+Period".action.consume-or-expel-window-right = [ ];

          "Mod+R".action.switch-preset-column-width = [ ];
          "Mod+Shift+R".action.switch-preset-window-height = [ ];

          "Mod+F".action.maximize-column = [ ];
          "Mod+Shift+F".action.fullscreen-window = [ ];

          # Screenshot bindings (adapted from Hyprland workflow):
          # Since Niri doesn't support submaps, using modifier combinations instead
          "Print" = {
            action.screenshot = {
              show-pointer = false;
            };
          };
          "Alt+Print".action.screenshot-window = [ ];
          "Mod+Print".action.screenshot-screen = [ ];

          # Shift+Print variants (save to disk instead of clipboard-only)
          "Shift+Print".action.screenshot = [ ];
          "Alt+Shift+Print" = {
            action.screenshot-window = {
              show-pointer = false;
            };
          };
          "Mod+Shift+Print" = {
            action.screenshot-screen = {
              show-pointer = false;
            };
          };

          "Mod+I".action.spawn = "notify-send \"niri\" \"No window inspector configured\"";
          "Mod+Shift+Period".action.spawn = "smile";

          "Ctrl+Shift+B".action.spawn = "killall -SIGUSR1 .waybar-wrapped";

          "XF86AudioRaiseVolume".action.spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "2.5%+"
          ];
          "XF86AudioLowerVolume".action.spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "2.5%-"
          ];
          "XF86AudioMute".action.spawn = [
            "wpctl"
            "set-mute"
            "@DEFAULT_AUDIO_SINK@"
            "toggle"
          ];
          "XF86MonBrightnessUp".action.spawn = [
            "light"
            "-A"
            "5"
          ];
          "XF86MonBrightnessDown".action.spawn = [
            "light"
            "-U"
            "5"
          ];
          "XF86AudioPlay".action.spawn = [
            "playerctl"
            "play-pause"
          ];
          "XF86AudioNext".action.spawn = [
            "playerctl"
            "next"
          ];
          "XF86AudioPrev".action.spawn = [
            "playerctl"
            "previous"
          ];
          "XF86AudioStop".action.spawn = [
            "playerctl"
            "stop"
          ];
        }
        // workspaceDigitBinds
        // workspaceMoveBinds
        // workspaceSilentMoveBinds;
    }
  );
}
