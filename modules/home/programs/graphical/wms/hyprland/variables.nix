{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe getExe';

  convert = getExe' pkgs.imagemagick "convert";
  wl-copy = getExe' pkgs.wl-clipboard "wl-copy";
  wl-paste = getExe' pkgs.wl-clipboard "wl-paste";

  getDateTime = getExe (
    pkgs.writeShellScriptBin "getDateTime" # bash
      ''
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
        area = "${getExe config.programs.hyprshot.package} -m region --freeze --raw | ${convert} png:- ppm:-";
        active = "${getExe config.programs.hyprshot.package} -m active -m window --raw | ${convert} png:- ppm:-";
        screen = "${getExe config.programs.hyprshot.package} -m output --raw | ${convert} png:- ppm:-";
        area_file = "${getExe config.programs.hyprshot.package} -m region --freeze -o \"${screenshot-path}\" -f \"$(${getDateTime}).png\"";
        active_file = "${getExe config.programs.hyprshot.package} -m active -m window -o \"${screenshot-path}\" -f \"$(${getDateTime}).png\"";
        screen_file = "${getExe config.programs.hyprshot.package} -m output -o \"${screenshot-path}\" -f \"$(${getDateTime}).png\"";
        area_clipboard = "${getExe config.programs.hyprshot.package} -m region --freeze --clipboard-only";
        active_clipboard = "${getExe config.programs.hyprshot.package} -m active -m window --clipboard-only";
        screen_clipboard = "${getExe config.programs.hyprshot.package} -m output --clipboard-only";
      }
    else
      {
        # Use PPM format for better performance with annotation tools
        area = "${getExe pkgs.grimblast} --freeze --type ppm save area -";
        active = "${getExe pkgs.grimblast} --type ppm save active -";
        screen = "${getExe pkgs.grimblast} --type ppm save screen -";
        area_file = "${getExe pkgs.grimblast} --freeze --notify save area \"${screenshot-path}/$(${getDateTime}).png\"";
        active_file = "${getExe pkgs.grimblast} --notify save active \"${screenshot-path}/$(${getDateTime}).png\"";
        screen_file = "${getExe pkgs.grimblast} --notify save screen \"${screenshot-path}/$(${getDateTime}).png\"";
        area_clipboard = "${getExe pkgs.grimblast} --freeze --notify copy area";
        active_clipboard = "${getExe pkgs.grimblast} --notify copy active";
        screen_clipboard = "${getExe pkgs.grimblast} --notify copy screen";
      };

  # Annotation tool priority: satty (if enabled) > swappy
  annotation_tool =
    if config.khanelinix.programs.graphical.addons.satty.enable then
      "${getExe pkgs.satty} --filename -"
    else
      "${getExe pkgs.swappy} -f -";

  cfg = config.khanelinix.programs.graphical.wms.hyprland;
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
          enforce_permissions = true;
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
          font_family = lib.mkDefault "MonaspaceNeon";
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
        # "$term" = "[float;tile] ${getExe pkgs.wezterm} start --always-new-process";
        "$term" = "${getExe pkgs.kitty}";
        "$browser" = "${getExe config.programs.firefox.package}";
        "$mail" = "${getExe pkgs.thunderbird}";
        "$editor" = "${getExe pkgs.neovim}";
        "$explorer" = "${getExe pkgs.nautilus}";
        "$music" = "${getExe pkgs.youtube-music}";
        "$notification_center" = "${getExe' config.services.swaync.package "swaync-client"}";
        "$launcher" = "${getExe pkgs.sherlock-launcher}";
        "$launcher-alt" = "${getExe config.programs.anyrun.package}";
        "$looking-glass" = "${getExe pkgs.looking-glass-client}";
        "$screen-locker" = "${getExe config.programs.hyprlock.package}";
        "$window-inspector" = "${getExe pkgs.hyprprop}";
        "$screen-recorder" = "${getExe pkgs.khanelinix.record_screen}";
        "$bar" = ".waybar-wrapped";

        # screenshot commands
        "$notify-screenshot" = ''${getExe pkgs.libnotify} --icon "$file" "Screenshot Saved"'';
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
          "${getExe pkgs.hyprpicker} -a && (${convert} -size 32x32 xc:$(${wl-paste}) /tmp/color.png && ${getExe pkgs.libnotify} \"Color Code:\" \"$(${wl-paste})\" -h \"string:bgcolor:$(${wl-paste})\" --icon /tmp/color.png -u critical -t 4000)";
        "$cliphist" =
          "${getExe pkgs.cliphist} list | ${getExe config.programs.anyrun.package} --show-results-immediately true | ${getExe pkgs.cliphist} decode | ${wl-copy}";
      };
    };
  };
}
