{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe getExe';

  convert = getExe' pkgs.imagemagick "convert";
  grimblast = getExe pkgs.grimblast;
  wl-copy = getExe' pkgs.wl-clipboard "wl-copy";
  wl-paste = getExe' pkgs.wl-clipboard "wl-paste";

  getDateTime = getExe (
    pkgs.writeShellScriptBin "getDateTime" # bash
      ''
        echo $(date +'%Y%m%d_%H%M%S')
      ''
  );

  screenshot-path = "/home/${config.khanelinix.user.name}/Pictures/screenshots";

  cfg = config.khanelinix.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        animations = {
          enabled = "yes";
          first_launch_animation = true; # fade in on first launch

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

        gestures = {
          workspace_swipe = true;
          workspace_swipe_fingers = 3;
          workspace_swipe_invert = false;
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
          swallow_regex = "foot|thunar|nemo|wezterm"; # windows for which swallow is applied
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
        "$launcher" = "${getExe config.programs.anyrun.package}";
        # "$launcher_alt" = "${getExe config.programs.rofi.package} -show drun -n";
        # "$launcher_shift" = "${getExe config.programs.rofi.package} -show run -n";
        # "$launchpad" = "${getExe config.programs.rofi.package} -show drun -config '~/.config/rofi/appmenu/rofi.rasi'";
        "$looking-glass" = "${getExe pkgs.looking-glass-client}";
        "$screen-locker" = "${getExe config.programs.hyprlock.package}";
        "$window-inspector" = "${getExe pkgs.hyprprop}";
        "$screen-recorder" = "${getExe pkgs.khanelinix.record_screen}";
        "$bar" = ".waybar-wrapped";

        # screenshot commands
        "$notify-screenshot" = ''${getExe pkgs.libnotify} --icon "$file" "Screenshot Saved"'';
        "$screenshot-path" = "/home/${config.khanelinix.user.name}/Pictures/screenshots";
        "$grimblast_area_file" =
          ''${grimblast} --freeze --notify save area "${screenshot-path}/$(${getDateTime}).png"'';
        "$grimblast_active_file" =
          ''${grimblast} --notify save active "${screenshot-path}/$(${getDateTime}).png"'';
        "$grimblast_screen_file" =
          ''${grimblast} --notify save screen "${screenshot-path}/$(${getDateTime}).png"'';
        "$grimblast_area_swappy" = ''${grimblast} --freeze save area - | ${getExe pkgs.swappy} -f -'';
        "$grimblast_active_swappy" = ''${grimblast} save active - | ${getExe pkgs.swappy} -f -'';
        "$grimblast_screen_swappy" = ''${grimblast} save screen - | ${getExe pkgs.swappy} -f -'';
        "$grimblast_area_clipboard" = "${grimblast} --freeze --notify copy area";
        "$grimblast_active_clipboard" = "${grimblast} --notify copy active";
        "$grimblast_screen_clipboard" = "${grimblast} --notify copy screen";

        # utility commands
        "$color_picker" =
          "${getExe pkgs.hyprpicker} -a && (${convert} -size 32x32 xc:$(${wl-paste}) /tmp/color.png && ${getExe pkgs.libnotify} \"Color Code:\" \"$(${wl-paste})\" -h \"string:bgcolor:$(${wl-paste})\" --icon /tmp/color.png -u critical -t 4000)";
        "$cliphist" =
          "${getExe pkgs.cliphist} list | ${getExe config.programs.anyrun.package} --show-results-immediately true | ${getExe pkgs.cliphist} decode | ${wl-copy}";
      };
    };
  };
}
