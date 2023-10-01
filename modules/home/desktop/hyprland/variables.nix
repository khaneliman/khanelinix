{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.desktop.hyprland;
in
{
  config =
    mkIf cfg.enable
      {
        wayland.windowManager.hyprland = {
          settings = {
            animations = {
              enabled = "yes";

              # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
              bezier = [
                "myBezier, 0.05, 0.9, 0.1, 1.05"
                "overshot, 0.13, 0.99, 0.29, 1.1"
                "scurve, 0.98, 0.01, 0.02, 0.98"
                "easein, 0.47, 0, 0.745, 0.715"
              ];

              animation = [
                "windowsOut, 1, 7, default, popin 10%"
                "windows, 1, 5, overshot, popin 10%"
                "border, 1, 10, default"
                "fade, 1, 10, default"
                "workspaces, 1, 6, overshot, slide"
              ];
            };

            decoration = {
              rounding = 10;

              active_opacity = 0.95;
              inactive_opacity = 0.9;
              fullscreen_opacity = 1.0;

              blur = {
                enabled = "yes";
                size = 5;
                passes = 4;
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
              pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
              preserve_split = true; # you probably want this
              force_split = 0;
            };

            general = {
              gaps_in = 5;
              gaps_out = 20;
              border_size = 2;
              "col.inactive_border" = "rgb(5e6798)";
              "col.active_border" = "rgba(7793D1FF)";
              layout = "dwindle";
              no_cursor_warps = true;
            };

            gestures = {
              workspace_swipe = true;
              workspace_swipe_invert = false;
              workspace_swipe_fingers = 3;
            };

            input = {
              kb_layout = "us";
              follow_mouse = 1;

              touchpad = {
                natural_scroll = "no";
                disable_while_typing = true;
                tap-to-click = true;
              };

              sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
            };

            master = {
              # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
              new_is_master = true;
            };

            misc = {
              mouse_move_enables_dpms = true;
              key_press_enables_dpms = true;
              vrr = 2;
            };

            "$mainMod" = "SUPER";
            "$LHYPER" = "SUPER_LALT_LCTRL"; # TODO: fix
            "$RHYPER" = "SUPER_RALT_RCTRL"; # TODO: fix

            # default applications
            "$term" = "${getExe pkgs.kitty}";
            "$browser" = "${getExe pkgs.firefox}";
            "$mail" = "${getExe pkgs.thunderbird}";
            "$editor" = "${getExe pkgs.neovim}";
            "$explorer" = "${getExe pkgs.xfce.thunar}";
            "$music" = "${getExe pkgs.spotify}";
            "$notepad" = "code - -profile notepad - -unity-launch ~/Templates";
            "$launcher" = "${getExe pkgs.rofi} -show drun -n";
            "$launcher_alt" = "${getExe pkgs.rofi} -show run -n";
            "$launchpad" = "${getExe pkgs.rofi} -show drun -config '~/.config/rofi/appmenu/rofi.rasi'";
            "$looking-glass" = "${getExe pkgs.looking-glass-client}";
          };
        };
      };
}
