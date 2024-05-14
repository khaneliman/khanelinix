{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (inputs) nixpkgs-wayland hyprland-contrib;
  inherit (lib) mkIf getExe getExe';

  convert = getExe' pkgs.imagemagick "convert";
  grimblast = getExe hyprland-contrib.packages.${system}.grimblast;
  wl-copy = getExe' nixpkgs-wayland.packages.${system}.wl-clipboard "wl-copy";
  wl-paste = getExe' nixpkgs-wayland.packages.${system}.wl-clipboard "wl-paste";

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

        debug = {
          disable_logs = false;
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

          drop_shadow = true;
          shadow_ignore_window = true;
          shadow_range = 20;
          shadow_render_power = 3;
          "col.shadow" = "0x55161925";
          "col.shadow_inactive" = "0x22161925";
        };

        dwindle = {
          # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
          force_split = 0;
          preserve_split = true; # you probably want this
          pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        };

        general = {
          allow_tearing = true;
          border_size = 2;
          "col.active_border" = "rgba(7793D1FF)";
          "col.inactive_border" = "rgb(5e6798)";
          gaps_in = 5;
          gaps_out = 20;
          layout = "dwindle";
        };

        gestures = {
          workspace_swipe = true;
          workspace_swipe_fingers = 3;
          workspace_swipe_invert = false;
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
          repeat_delay = 300; # Mimic the responsiveness of mac setup
          repeat_rate = 50; # Mimic the responsiveness of mac setup
        };

        master = {
          # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
          new_is_master = true;
        };

        misc = {
          allow_session_lock_restore = true;
          disable_hyprland_logo = true;
          key_press_enables_dpms = true;
          mouse_move_enables_dpms = true;
          vrr = 2;
        };

        # unscale XWayland
        xwayland = {
          force_zero_scaling = true;
        };

        "$mainMod" = "SUPER";
        "$LHYPER" = "SUPER_LALT_LCTRL"; # TODO: fix
        "$RHYPER" = "SUPER_RALT_RCTRL"; # TODO: fix

        # default applications
        "$term" = "[float;tile] ${getExe pkgs.wezterm} start --always-new-process";
        "$browser" = "${getExe pkgs.firefox}";
        "$mail" = "${getExe pkgs.thunderbird}";
        "$editor" = "${getExe pkgs.neovim}";
        "$explorer" = "${getExe pkgs.xfce.thunar}";
        "$music" = "${getExe pkgs.spotify}";
        "$notification_center" = "${getExe' config.services.swaync.package "swaync-client"}";
        "$launcher" = "${getExe config.programs.rofi.package} -show drun -n";
        "$launcher_alt" = "${getExe config.programs.rofi.package} -show calc";
        "$launcher_shift" = "${getExe config.programs.rofi.package} -show run -n";
        "$launchpad" = "${getExe config.programs.rofi.package} -show drun -config '~/.config/rofi/appmenu/rofi.rasi'";
        "$looking-glass" = "${getExe pkgs.looking-glass-client}";
        "$screen-locker" = "${getExe config.programs.hyprlock.package}";
        "$window-inspector" = "${getExe hyprland-contrib.packages.${system}.hyprprop}";
        "$screen-recorder" = "${getExe pkgs.khanelinix.record_screen}";

        # screenshot commands
        "$notify-screenshot" = ''${getExe pkgs.libnotify} --icon "$file" "Screenshot Saved"'';
        "$screenshot-path" = "/home/${config.khanelinix.user.name}/Pictures/screenshots";
        "$grimblast_area_file" = ''file="${screenshot-path}/$(${getDateTime}).png" && ${grimblast} --freeze --notify save area "$file"'';
        "$grimblast_active_file" = ''file="${screenshot-path}/$(${getDateTime}).png" && ${grimblast} --notify save active "$file"'';
        "$grimblast_screen_file" = ''file="${screenshot-path}/$(${getDateTime}).png" && ${grimblast} --notify save screen "$file"'';
        "$grimblast_area_swappy" = ''${grimblast} --freeze save area - | ${getExe pkgs.swappy} -f -'';
        "$grimblast_active_swappy" = ''${grimblast} save active - | ${getExe pkgs.swappy} -f -'';
        "$grimblast_screen_swappy" = ''${grimblast} save screen - | ${getExe pkgs.swappy} -f -'';
        "$grimblast_area_clipboard" = "${grimblast} --freeze --notify copy area";
        "$grimblast_active_clipboard" = "${grimblast} --notify copy active";
        "$grimblast_screen_clipboard" = "${grimblast} --notify copy screen";

        # utility commands
        "$color_picker" = "${getExe pkgs.hyprpicker} -a && (${convert} -size 32x32 xc:$(${wl-paste}) /tmp/color.png && ${getExe pkgs.libnotify} \"Color Code:\" \"$(${wl-paste})\" -h \"string:bgcolor:$(${wl-paste})\" --icon /tmp/color.png -u critical -t 4000)";
        "$cliphist" = "${getExe pkgs.cliphist} list | ${getExe config.programs.rofi.package} -dmenu | ${getExe pkgs.cliphist} decode | ${wl-copy}";
      };
    };
  };
}
