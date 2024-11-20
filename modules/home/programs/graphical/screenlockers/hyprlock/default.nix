{
  config,
  lib,
  osConfig,
  root,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  catppuccin = import (root + "/modules/home/theme/catppuccin/colors.nix");

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
            size = "200, 50";
            position = "0, -80";
            outline_thickness = 5;
            dots_center = true;
            outer_color = catppuccin.colors.crust.rgb;
            inner_color = catppuccin.colors.surface2.rgb;
            font_color = catppuccin.colors.text.rgb;
            fade_on_empty = false;
            placeholder_text = "<span foreground=\"##cad3f5\">Password...</span>";
            shadow_passes = 2;
            bothlock_color = -1;
            capslock_color = "-1";
            check_color = "rgb(204, 136, 34)";
            dots_rounding = "-1";
            dots_size = "0.330000";
            dots_spacing = "0.150000";
            fade_timeout = "2000";
            fail_color = "rgb(204, 34, 34)";
            fail_text = "<i>$FAIL</i>";
            fail_transition = 300;
            halign = "center";
            hide_input = false;
            invert_numlock = false;
            numlock_color = -1;
            rounding = -1;
            shadow_boost = "1.200000";
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_size = 3;
            swap_font_color = false;
            valign = "center";
          }
        ];

        image = [
          {
            monitor = "";
            size = 120;
            position = "0, 45";
            path = "/home/${config.snowfallorg.user.name}/.face";
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
            text = "<span font_weight=\"ultrabold\">$TIME</span>";
            color = catppuccin.colors.text.rgb;
            font_size = 100;
            font_family = osConfig.khanelinix.system.fonts.default;
            valign = "center";
            halign = "center";
            position = "0, 330";
            shadow_passes = 2;
            rotate = "0.000000";
            shadow_boost = "1.200000";
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_size = 3;
          }
          {
            monitor = "";
            text = "<span font_weight=\"bold\"> $USER</span>";
            color = catppuccin.colors.text.rgb;
            font_size = 25;
            font_family = osConfig.khanelinix.system.fonts.default;
            valign = "top";
            halign = "left";
            position = "10, 0";
            shadow_passes = 1;
            rotate = "0.000000";
            shadow_boost = "1.200000";
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_size = 3;
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
            text = "<span font_weight=\"bold\">Locked</span>";
            color = catppuccin.colors.text.rgb;
            font_size = 25;
            font_family = osConfig.khanelinix.system.fonts.default;
            valign = "center";
            halign = "center";
            position = "0, -430";
            shadow_passes = 1;
            rotate = "0.000000";
            shadow_boost = "1.200000";
            shadow_color = "rgba(0, 0, 0, 1.0)";
            shadow_size = 3;
          }
          {
            monitor = "";
            text = "cmd[update:120000] echo \"<span font_weight='bold'>$(date +'%a %d %B')</span>\"";
            color = catppuccin.colors.text.rgb;
            font_size = 30;
            font_family = osConfig.khanelinix.system.fonts.default;
            valign = "center";
            halign = "center";
            position = "0, 210";
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
        ];
      };
    };
  };
}
