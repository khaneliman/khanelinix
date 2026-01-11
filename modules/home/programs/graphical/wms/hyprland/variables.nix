{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  magick = lib.getExe' pkgs.imagemagick "magick";
  wl-copy = lib.getExe' pkgs.wl-clipboard "wl-copy";
  wl-paste = lib.getExe' pkgs.wl-clipboard "wl-paste";

  getDateTime = lib.getExe (
    pkgs.writeShellScriptBin "getDateTime" /* bash */ ''
      echo $(date +'%Y%m%d_%H%M%S')
    ''
  );

  screenshot-path = "/home/${config.khanelinix.user.name}/Pictures/screenshots";

  # Screenshot tool priority: hyprshot (if enabled) > grimblast
  screenshot_tool =
    if config.programs.hyprshot.enable then
      {
        # Note: hyprshot --raw outputs PNG format, but satty expects PPM for best performance
        # We convert PNG to PPM using imagemagick for compatibility
        area = "hyprshot -m region --freeze --raw | ${magick} convert png:- ppm:-";
        active = "hyprshot -m active -m window --raw | ${magick} convert png:- ppm:-";
        screen = "hyprshot -m output --raw | ${magick} convert png:- ppm:-";
        area_file = "hyprshot -m region --freeze -o \"${screenshot-path}\" -f \"$(${getDateTime}).png\"";
        active_file = "hyprshot -m active -m window -o \"${screenshot-path}\" -f \"$(${getDateTime}).png\"";
        screen_file = "hyprshot -m output -o \"${screenshot-path}\" -f \"$(${getDateTime}).png\"";
        area_clipboard = "hyprshot -m region --freeze --clipboard-only";
        active_clipboard = "hyprshot -m active -m window --clipboard-only";
        screen_clipboard = "hyprshot -m output --clipboard-only";
      }
    else
      {
        # Use PPM format for better performance with annotation tools
        area = "grimblast --freeze --type ppm save area -";
        active = "grimblast --type ppm save active -";
        screen = "grimblast --type ppm save screen -";
        area_file = "grimblast --freeze --notify save area \"${screenshot-path}/$(${getDateTime}).png\"";
        active_file = "grimblast --notify save active \"${screenshot-path}/$(${getDateTime}).png\"";
        screen_file = "grimblast --notify save screen \"${screenshot-path}/$(${getDateTime}).png\"";
        area_clipboard = "grimblast --freeze --notify copy area";
        active_clipboard = "grimblast --notify copy active";
        screen_clipboard = "grimblast --notify copy screen";
      };

  # Annotation tool priority: satty (if enabled) > swappy
  annotation_tool =
    if config.khanelinix.programs.graphical.addons.satty.enable then
      "satty --filename -"
    else
      "swappy -f -";

  cfg = config.khanelinix.programs.graphical.wms.hyprland;

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
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        animations = {
          enabled = "yes";

          # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
          bezier = [
            "easein, 0.47, 0, 0.745, 0.715"
            "myBezier, 0.05, 0.9, 0.1, 1.05"
            "overshot, 0.13, 0.99, 0.29, 1.1"
            "scurve, 0.98, 0.01, 0.02, 0.98"
          ];

          animation = [
            "border, 1, 10, default"
            "fade, 1, 10, default"
            "windows, 1, 5, overshot, popin 10%"
            "windowsOut, 1, 7, default, popin 10%"
            "workspaces, 1, 6, overshot, slide"
          ];
        };

        cursor = {
          enable_hyprcursor = true;
          sync_gsettings_theme = true;
        };

        debug = mkIf cfg.enableDebug {
          colored_stdout_logs = true;
          disable_logs = false;
          enable_stdout_logs = true;
          error_position = -1;
        };

        decoration = {
          active_opacity = 0.95;
          fullscreen_opacity = 1.0;
          inactive_opacity = 0.9;
          rounding = 10;

          blur = {
            enabled = "yes";
            passes = 4;
            size = 5;
          };

          shadow = {
            enabled = true;
            ignore_window = true;
            range = 20;
            render_power = 3;
            color = lib.mkDefault "0x55161925";
            color_inactive = lib.mkDefault "0x22161925";
          };
        };

        dwindle = {
          # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
          # force_split = 0;
          preserve_split = true; # you probably want this
          pseudotile = false; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          # no_gaps_when_only = false;
          special_scale_factor = 0.9;
        };

        ecosystem = {
          no_donation_nag = true;
        };

        general = {
          # allow_tearing = true;
          border_size = 2;
          "col.active_border" = lib.mkDefault "rgba(7793D1FF)";
          "col.inactive_border" = lib.mkDefault "rgb(5e6798)";
          gaps_in = 5;
          gaps_out = 20;
          layout = "dwindle";
        };

        group = {
          # new windows in a group spawn after current or at group tail
          insert_after_current = true;
          # focus on the window that has just been moved out of the group
          focus_removed_window = true;

          "col.border_active" = lib.mkDefault "rgba(88888888)";
          "col.border_inactive" = lib.mkDefault "rgba(00000088)";

          groupbar = {
            # groupbar stuff
            # this removes the ugly gradient around grouped windows - which sucks
            gradients = false;
            font_size = 14;

            # titles look ugly, and I usually know what I'm looking at
            render_titles = false;

            # scrolling in the groupbar changes group active window
            scrolling = true;
          };
        };

        input = {
          follow_mouse = 1;
          kb_layout = "us";
          numlock_by_default = true;

          touchpad = {
            disable_while_typing = true;
            natural_scroll = "no";
            tap-to-click = true;
          };

          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
          scroll_factor = 1.0;
          emulate_discrete_scroll = 1;
          # repeat_delay = 500; # Mimic the responsiveness of mac setup
          # repeat_rate = 50; # Mimic the responsiveness of mac setup
        };

        master = {
          # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
          new_status = "master";
        };

        misc = {
          allow_session_lock_restore = true;
          disable_hyprland_logo = true;
          enable_swallow = true; # hide windows that spawn other windows
          font_family = lib.mkDefault "MonaspaceNeon NF";
          key_press_enables_dpms = true;
          middle_click_paste = false;
          mouse_move_enables_dpms = true;
          swallow_regex = ".*(foot|thunar|nemo|wezterm).*"; # windows for which swallow is applied
          vrr = 2;
        };

        # unscale XWayland
        xwayland = {
          force_zero_scaling = false;
        };

        "$mainMod" = "SUPER";
        "$HYPER" = "SUPER_SHIFT_CTRL";
        "$ALT-HYPER" = "SHIFT_ALT_CTRL";
        "$RHYPER" = "SUPER_ALT_R_CTRL_R";
        "$LHYPER" = "SUPER_ALT_L_CTRL_L";

        # default applications
        # FIX: broken clipboard with new hyprland impl
        # "$term" = "[float;tile] wezterm start --always-new-process";
        "$bar" = ".waybar-wrapped";
        "$browser" = "${lib.getExe config.programs.firefox.package}";
        "$editor" = "nvim";
        "$explorer" = "nautilus";
        "$looking-glass" = "looking-glass-client";
        "$mail" = "thunderbird";
        "$music" = "pear-desktop";
        "$notification_center" = "swaync-client";
        "$screen-locker" = "hyprlock";
        "$screen-recorder" = "record_screen";
        "$term" = "kitty";
        "$window-inspector" = "hyprprop";

        "$launcher" = mkIf (count > 0) (builtins.elemAt enabledLaunchers 0);
        "$launcher-alt" = mkIf (count > 1) (builtins.elemAt enabledLaunchers 1);
        "$launcher-backup" = mkIf (count > 2) (builtins.elemAt enabledLaunchers 2);

        # screenshot commands
        "$notify-screenshot" = ''notify-send --icon "$file" "Screenshot Saved"'';
        "$screenshot-path" = "/home/${config.khanelinix.user.name}/Pictures/screenshots";
        "$screenshot_area_file" = screenshot_tool.area_file;
        "$screenshot_active_file" = screenshot_tool.active_file;
        "$screenshot_screen_file" = screenshot_tool.screen_file;
        "$screenshot_area_clipboard" = screenshot_tool.area_clipboard;
        "$screenshot_active_clipboard" = screenshot_tool.active_clipboard;
        "$screenshot_screen_clipboard" = screenshot_tool.screen_clipboard;
        "$screenshot_area_annotate" = "${screenshot_tool.area} | ${annotation_tool}";
        "$screenshot_active_annotate" = "${screenshot_tool.active} | ${annotation_tool}";
        "$screenshot_screen_annotate" = "${screenshot_tool.screen} | ${annotation_tool}";

        # utility commands
        "$color_picker" =
          /* Bash */ "hyprpicker -a && (${magick} convert -size 32x32 xc:$(${wl-paste}) /tmp/color.png && notify-send \"Color Code:\" \"$(${wl-paste})\" -h \"string:bgcolor:$(${wl-paste})\" --icon /tmp/color.png -u critical -t 4000)";
        "$cliphist" =
          let
            enabledDmenuLaunchers = lib.flatten [
              (lib.optional launchers.vicinae.enable "vicinae dmenu")
              (lib.optional launchers.anyrun.enable "anyrun --show-results-immediately true")
              (lib.optional launchers.walker.enable "walker --stream")
              (lib.optional launchers.sherlock.enable "sherlock")
              (lib.optional launchers.rofi.enable "rofi -dmenu")
            ];
          in
          /* Bash */ "cliphist list | ${builtins.head enabledDmenuLaunchers} | cliphist decode | ${wl-copy}";
      };
    };
  };
}
