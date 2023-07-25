{
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.hyprland;
in {
  config =
    mkIf cfg.enable
    {
      wayland.windowManager.hyprland = {
        settings = {
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

          general = {
            gaps_in = 5;
            gaps_out = 20;
            border_size = 2;
            "col.inactive_border" = "rgb(5e6798)";
            "col.active_border" = "rgba(7793D1FF)";

            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            multisample_edges = true;

            active_opacity = 0.95;
            inactive_opacity = 0.9;
            fullscreen_opacity = 1.0;

            blur = "yes";
            blur_size = 5;
            blur_passes = 4;
            blur_new_optimizations = "on";

            drop_shadow = true;
            shadow_ignore_window = true;
            shadow_range = 20;
            shadow_render_power = 3;
            "col.shadow" = "0x55161925";
            "col.shadow_inactive" = "0x22161925";
          };

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

          dwindle = {
            # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
            pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true; # you probably want this
            force_split = 0;
          };

          master = {
            # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
            new_is_master = true;
          };

          gestures = {
            workspace_swipe = true;
            workspace_swipe_invert = false;
            workspace_swipe_fingers = 3;
          };

          "$mainMod" = "SUPER";
          "$LHYPER" = "SUPER_LALT_LCTRL"; # TODO: fix
          "$RHYPER" = "SUPER_RALT_RCTRL"; # TODO: fix

          # default applications
          "$term" = "kitty";
          "$browser" = "firefox-developer-edition";
          "$mail" = "thunderbird";
          "$editor" = "nvim";
          "$explorer" = "thunar";
          "$music" = "spotify";
          "$notepad" = "code - -profile notepad - -unity-launch ~/Templates";
          "$launcher" = "rofi -show drun -n";
          "$launcher_alt" = "rofi -show run -n";
          "$launchpad" = "rofi -show drun -config '~/.config/rofi/appmenu/rofi.rasi'";
          "$looking-glass" = "looking-glass-client";

          # TODO: dynamic configuration support instead of hard coded
          "$w1" = "hyprctl hyprpaper wallpaper \"DP-3,~/.local/share/wallpapers/catppuccin/flatppuccin_macchiato.png\"";
          "$w2" = "hyprctl hyprpaper wallpaper \"DP-1,~/.local/share/wallpapers/catppuccin/buttons.png\"";
          "$w3" = "hyprctl hyprpaper wallpaper \"DP-1,~/.local/share/wallpapers/catppuccin/cat_pacman.png\"";
          "$w4" = "hyprctl hyprpaper wallpaper \"DP-1,~/.local/share/wallpapers/catppuccin/cat-sound.png\"";
          "$w5" = "hyprctl hyprpaper wallpaper \"DP-1,~/.local/share/wallpapers/catppuccin/hashtags-black.png\"";
          "$w6" = "hyprctl hyprpaper wallpaper \"DP-1,~/.local/share/wallpapers/catppuccin/hashtags-new.png\"";
          "$w7" = "hyprctl hyprpaper wallpaper \"DP-1,~/.local/share/wallpapers/catppuccin/hearts.png\"";
          "$w8" = "hyprctl hyprpaper wallpaper \"DP-1,~/.local/share/wallpapers/catppuccin/tetris.png\"";
        };
      };
    };
}
