{
  config,
  khanelinix-lib,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  catppuccin = import (khanelinix-lib.getFile "modules/home/theme/catppuccin/colors.nix");

  cfg = config.khanelinix.programs.graphical.screenlockers.hyprlock;
in
{
  options.khanelinix.programs.graphical.screenlockers.hyprlock = {
    enable = mkBoolOpt false "Whether to enable hyprlock in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
          grace = 300;
          no_fade_in = false;
          no_fade_out = false;
        };

        background = [
          {
            monitor = "";
            brightness = "0.817200";
            color = "rgba(25, 20, 20, 1.0)";
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            contrast = "0.891700";
            noise = "0.011700";
            vibrancy = "0.168600";
            vibrancy_darkness = "0.050000";
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "300, 50";
            outline_thickness = 1;
            rounding = 10;
            dots_size = "0.25";
            dots_spacing = "0.4";
            dots_center = true;
            outer_color = catppuccin.colors.crust.rgb;
            inner_color = catppuccin.colors.surface2.rgb;
            font_color = catppuccin.colors.text.rgb;
            font_size = 14;
            font_family = "Maple Mono Bold";
            fade_on_empty = false;
            placeholder_text = "<i><span foreground=\"##fbf1c7\">Enter Password</span></i>";
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
            path = "/home/${config.khanelinix.user.name}/.face";
            border_color = catppuccin.colors.text.rgb;
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
            color = catppuccin.colors.text.rgb;
            text = "cmd[update:1000] echo \"$(date +\"%k:%M\")\"";
            font_size = 115;
            font_family = "Maple Mono Bold";
            shadow_passes = 3;
            position = "0, -150";
            halign = "center";
            valign = "top";
          }
          {
            monitor = "";
            text = "<span font_weight=\"ultrabold\">󰌾 </span>";
            color = catppuccin.colors.text.rgb;
            font_size = 50;
            font_family = osConfig.khanelinix.system.fonts.default;
            valign = "center";
            halign = "center";
            position = "15, -350";
            shadow_passes = 1;
            rotate = "0.000000";
            shadow_boost = "1.200000";
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_size = 3;
          }
          {
            monitor = "";
            text = "<span font_weight=\"ultrabold\"> </span>";
            color = catppuccin.colors.text.rgb;
            font_size = 25;
            font_family = osConfig.khanelinix.system.fonts.default;
            valign = "bottom";
            halign = "right";
            position = "5, 8";
            shadow_passes = 1;
            rotate = "0.000000";
            shadow_boost = "1.200000";
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_size = 3;
          }
          {
            monitor = "";
            color = catppuccin.colors.text.rgb;
            text = "cmd[update:1000] echo \"- $(date +\"%A, %B %d\") -\"";
            font_size = 18;
            font_family = "Maple Mono";
            shadow_passes = 3;
            position = "0, -350";
            halign = "center";
            valign = "top";
          }
          {
            monitor = "";
            color = catppuccin.colors.text.rgb;
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
            color = "rgba(102, 92, 84, .33)";
            rounding = 10;
            border_size = 0;
            border_color = "rgba(255, 255, 255, 0)";
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
