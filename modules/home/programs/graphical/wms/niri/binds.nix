{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.wms.niri;

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
  config = mkIf cfg.enable {
    wayland.windowManager.niri.settings.binds =
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
          if enabledDmenuLaunchers == [ ] then "rofi -dmenu" else builtins.elemAt enabledDmenuLaunchers 0;

        wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";

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
        notificationCommand = [
          "swaync-client"
          "-t"
          "-sw"
        ];
        lookingGlassCommand = "looking-glass-client";

        # vicinae dmenu returns nothing when any entry contains a control
        # character, so strip them (keeping tab) from the previews. cliphist
        # decode only reads the leading id, so the selection is unaffected.
        cliphistCommand = "cliphist list | tr -d '\\000-\\010\\013-\\037\\177' | ${dmenuLauncher} | cliphist decode | ${wlCopy}";

        colorPickerCommand = ''
          color="$(niri msg pick-color | awk '/Hex:/ { print $2 }')" &&
          [ -n "$color" ] &&
          printf '%s' "$color" | ${wlCopy} &&
          ${magick} convert -size 32x32 "xc:$color" /tmp/color.png &&
          notify-send "Color Code:" "$color" -h "string:bgcolor:$color" --icon /tmp/color.png -u critical -t 4000
        '';

        annotationCommand =
          if config.khanelinix.programs.graphical.addons.satty.enable then
            ''grim -g "$(slurp)" -t ppm - | satty --filename -''
          else
            ''grim -g "$(slurp)" - | swappy -f -'';

        workspaceDigitBinds = builtins.listToAttrs (
          map (
            ws:
            let
              key = if ws == 10 then "0" else toString ws;
            in
            {
              name = "Ctrl+Alt+${key}";
              value.focus-workspace = ws;
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
              value.move-column-to-workspace = ws;
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
              value.move-column-to-workspace = ws;
            }
          ) (lib.range 1 10)
        );

        launcherBinds =
          lib.optionalAttrs (defaultLauncher != null) {
            "Ctrl+Space" = {
              spawn = defaultLauncher;
              _props.allow-inhibiting = false;
            };
          }
          // lib.optionalAttrs (altLauncher != null) {
            "Alt+Space".spawn = altLauncher;
          }
          // lib.optionalAttrs (backupLauncher != null) {
            "Mod+Space".spawn = backupLauncher;
          };

        pickerBind = {
          "Mod+Shift+P".spawn = [
            "sh"
            "-c"
            colorPickerCommand
          ];
        };

        voxtypeBinds = lib.optionalAttrs config.khanelinix.services.voxtype.enable {
          "F13".spawn = [
            "voxtype"
            "record"
            "toggle"
          ];
          "Ctrl+Alt+D".spawn = [
            "voxtype"
            "record"
            "toggle"
          ];
          "F14".spawn = [
            "voxtype"
            "record"
            "cancel"
          ];
          "Ctrl+Alt+Shift+D".spawn = [
            "voxtype"
            "record"
            "cancel"
          ];
          # Select a corrected dictation, then teach VoxType the fixes.
          "Ctrl+Alt+F".spawn = [
            "voxtype"
            "learn"
            "--from-selection"
          ];
        };
      in
      launcherBinds
      // pickerBind
      // voxtypeBinds
      // {
        "Mod+Return".spawn = "kitty";
        "Mod+Shift+Return".spawn = [
          "kitty"
          "zellij"
        ];
        "Mod+B".spawn = browserCommand;
        "Mod+Shift+E".spawn = explorerCommand;
        "Mod+L".spawn = lockCommand;
        "Mod+N".spawn = notificationCommand;
        "Mod+V".spawn = [
          "sh"
          "-c"
          cliphistCommand
        ];
        "Mod+W".spawn = lookingGlassCommand;

        "Mod+E".spawn = [
          "kitty"
          "yazi"
        ];
        "Mod+T".spawn = [
          "kitty"
          "btop"
        ];

        "Mod+Q".close-window = { };
        "Ctrl+Shift+Q".close-window = { };

        # Focus bindings (matching Hyprland ALT pattern, adapted for Niri's scrolling)
        "Alt+Left".focus-column-left = { };
        "Alt+Right".focus-column-right = { };
        "Alt+H".focus-column-left = { };
        "Alt+L".focus-column-right = { };

        # Workspace focus bindings
        "Ctrl+Alt+Down".focus-workspace-down = { };
        "Ctrl+Alt+Up".focus-workspace-up = { };
        "Ctrl+Alt+J".focus-workspace-down = { };
        "Ctrl+Alt+K".focus-workspace-up = { };

        # Move window bindings (using Mod+Shift to avoid conflict with Mod+L lock)
        "Mod+Left".move-column-left = { };
        "Mod+Right".move-column-right = { };
        "Mod+Down".move-column-to-workspace-down = { };
        "Mod+Up".move-column-to-workspace-up = { };

        "Mod+Shift+H".move-column-left = { };
        "Mod+Shift+L".move-column-right = { };
        "Mod+Shift+J".move-column-to-workspace-down = { };
        "Mod+Shift+K".move-column-to-workspace-up = { };

        # Wheel scrolling
        "Mod+WheelScrollDown" = {
          _props.cooldown-ms = 150;
          focus-workspace-down = [ ];
        };
        "Mod+WheelScrollUp" = {
          _props.cooldown-ms = 150;
          focus-workspace-up = [ ];
        };
        "Mod+WheelScrollRight".focus-column-right = { };
        "Mod+WheelScrollLeft".focus-column-left = { };

        "Mod+Ctrl+Shift+K".move-column-to-monitor-up = { };
        "Mod+Ctrl+Shift+J".move-column-to-monitor-down = { };

        "Mod+Page_Down".focus-workspace-down = { };
        "Mod+Page_Up".focus-workspace-up = { };

        "Mod+Ctrl+Page_Down".move-column-to-workspace-down = { };
        "Mod+Ctrl+Page_Up".move-column-to-workspace-up = { };

        "Mod+1".focus-workspace = 1;
        "Mod+2".focus-workspace = 2;
        "Mod+3".focus-workspace = 3;
        "Mod+4".focus-workspace = 4;
        "Mod+5".focus-workspace = 5;

        "Mod+Ctrl+1".move-column-to-workspace = 1;
        "Mod+Ctrl+2".move-column-to-workspace = 2;
        "Mod+Ctrl+3".move-column-to-workspace = 3;
        "Mod+Ctrl+4".move-column-to-workspace = 4;
        "Mod+Ctrl+5".move-column-to-workspace = 5;

        "Mod+Comma".consume-or-expel-window-left = { };
        "Mod+Period".consume-or-expel-window-right = { };

        "Mod+R".switch-preset-column-width = { };
        "Mod+Shift+R".switch-preset-window-height = { };

        "Mod+F".maximize-column = { };
        "Mod+Shift+F".fullscreen-window = { };

        # Screenshot bindings (adapted from Hyprland workflow):
        # Since Niri doesn't support submaps, using modifier combinations instead
        "Print" = {
          screenshot._props.show-pointer = false;
        };
        "Alt+Print".screenshot-window = { };
        "Mod+Print".screenshot-screen = { };

        # Shift+Print variants (save to disk instead of clipboard-only)
        "Shift+Print".screenshot = { };
        "Alt+Shift+Print" = {
          screenshot-window._props.show-pointer = false;
        };
        "Mod+Shift+Print" = {
          screenshot-screen._props.show-pointer = false;
        };
        "Ctrl+Alt+Print".spawn = [
          "sh"
          "-c"
          annotationCommand
        ];

        "Mod+I".spawn = [
          "notify-send"
          "niri"
          "No window inspector configured"
        ];
        "Mod+Shift+Period".spawn = "smile";

        "Ctrl+Shift+B".spawn = [
          "killall"
          "-SIGUSR1"
          ".waybar-wrapped"
        ];

        "XF86AudioRaiseVolume".spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "2.5%+"
        ];
        "XF86AudioLowerVolume".spawn = [
          "wpctl"
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "2.5%-"
        ];
        "XF86AudioMute".spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ];
        "XF86MonBrightnessUp".spawn = [
          (lib.getExe pkgs.brightnessctl)
          "--class=backlight"
          "set"
          "5%+"
        ];
        "XF86MonBrightnessDown".spawn = [
          (lib.getExe pkgs.brightnessctl)
          "--class=backlight"
          "set"
          "5%-"
        ];
        "XF86AudioPlay".spawn = [
          "playerctl"
          "play-pause"
        ];
        "XF86AudioNext".spawn = [
          "playerctl"
          "next"
        ];
        "XF86AudioPrev".spawn = [
          "playerctl"
          "previous"
        ];
        "XF86AudioStop".spawn = [
          "playerctl"
          "stop"
        ];
      }
      // workspaceDigitBinds
      // workspaceMoveBinds
      // workspaceSilentMoveBinds;
  };
}
