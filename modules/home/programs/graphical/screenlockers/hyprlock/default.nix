{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  colors = config.khanelinix.theme.active;
  rgb = color: "rgb(${lib.removePrefix "#" color})";

  cfg = config.khanelinix.programs.graphical.screenlockers.hyprlock;
  layout = config.khanelinix.system.display.layout or null;
  backgrounds =
    if layout == null then
      [
        {
          monitor = "";
          path = "screenshot";
        }
      ]
    else
      map (output: {
        monitor = output.name;
        path = lib.khanelinix.theme.wallpaperPath {
          inherit config pkgs;
          name = config.khanelinix.theme.wallpaper.${output.wallpaper};
        };
      }) (lib.reverseList layout.outputs);
in
{
  options.khanelinix.programs.graphical.screenlockers.hyprlock = {
    enable = lib.mkEnableOption "hyprlock in the desktop environment";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      # Hyprlock documentation
      # See: https://wiki.hypr.land/Hypr-ecosystem/hyprlock/
      enable = true;

      settings = {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
          # NOTE: see if it helps with crashes
          screencopy_mode = 1;
        };

        animations = {
          enabled = true;
          fade_in = {
            duration = 300;
            bezier = "easeOutQuint";
          };
          fade_out = {
            duration = 300;
            bezier = "easeOutQuint";
          };
        };

        background = map (
          background:
          {
            brightness = "0.817200";
            color = rgb colors.background;
            blur_passes = 3;
            blur_size = 8;
            contrast = "0.891700";
            noise = "0.011700";
            vibrancy = "0.168600";
            vibrancy_darkness = "0.050000";
          }
          // background
        ) backgrounds;

        input-field = [
          {
            monitor = "";
            size = "300, 50";
            outline_thickness = 1;
            rounding = 10;
            dots_size = "0.25";
            dots_spacing = "0.4";
            dots_center = true;
            outer_color = rgb colors.accent;
            inner_color = rgb colors.surface;
            font_color = rgb colors.foreground;
            check_color = rgb colors.warning;
            fail_color = rgb colors.danger;
            capslock_color = rgb colors.warning;
            font_size = 14;
            font_family = "Maple Mono Bold";
            fade_on_empty = false;
            placeholder_text = "<i>Enter Password</i>";
            hide_input = false;
            position = "0, 200";
            halign = "center";
            valign = "bottom";
          }
        ];

        image = [
          {
            monitor = "";
            size = 120;
            position = "0, 45";
            path = "${config.khanelinix.user.home}/.face";
            border_color = rgb colors.foreground;
            border_size = 5;
            halign = "center";
            valign = "center";
            shadow_passes = 1;
            reload_cmd = "";
            reload_time = -1;
            rotate = "0.000000";
            rounding = "-1";
          }
        ];

        label = [
          {
            monitor = "";
            color = rgb colors.foreground;
            text = "cmd[update:1000] echo \"$(date +\"%k:%M\")\"";
            font_size = 115;
            font_family = "Maple Mono Bold";
            shadow_color = rgb colors.shadow;
            shadow_passes = 3;
            position = "0, -150";
            halign = "center";
            valign = "top";
          }
          {
            monitor = "";
            text = "<span font_weight=\"ultrabold\">󰌾 </span>";
            color = rgb colors.foreground;
            font_size = 50;
            font_family = lib.mkDefault config.khanelinix.system.fonts.default;
            valign = "center";
            halign = "center";
            position = "15, -350";
            shadow_passes = 1;
            rotate = "0.000000";
            shadow_boost = "1.200000";
            shadow_color = rgb colors.shadow;
            shadow_size = 3;
          }
          {
            monitor = "";
            text = "<span font_weight=\"ultrabold\"> </span>";
            color = rgb colors.foreground;
            font_size = 25;
            font_family = lib.mkDefault config.khanelinix.system.fonts.default;
            valign = "bottom";
            halign = "right";
            position = "5, 8";
            shadow_passes = 1;
            rotate = "0.000000";
            shadow_boost = "1.200000";
            shadow_color = rgb colors.shadow;
            shadow_size = 3;
          }
          {
            monitor = "";
            color = rgb colors.foreground;
            text = "cmd[update:1000] echo \"- $(date +\"%A, %B %d\") -\"";
            font_size = 18;
            font_family = "Maple Mono";
            shadow_color = rgb colors.shadow;
            shadow_passes = 3;
            position = "0, -350";
            halign = "center";
            valign = "top";
          }
          {
            monitor = "";
            color = rgb colors.foreground;
            text = "$USER";
            font_size = 15;
            font_family = "Maple Mono Bold";
            position = "0, 281";
            halign = "center";
            valign = "bottom";
          }
        ];

        shape = [
          {
            monitor = "";
            size = "300, 50";
            color = rgb colors.surface;
            rounding = 10;
            border_size = 0;
            border_color = lib.mkDefault "rgba(255, 255, 255, 0)";
            rotate = "0";
            position = "0, 270";
            halign = "center";
            valign = "bottom";
          }
        ];
      };
    };
  };
}
