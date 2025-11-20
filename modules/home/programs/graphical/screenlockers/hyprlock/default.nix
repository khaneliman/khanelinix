{
  config,
  lib,
  osConfig ? { },

  ...
}:
let
  inherit (lib) mkIf;

  catppuccin = import (lib.getFile "modules/home/theme/catppuccin/colors.nix");

  cfg = config.khanelinix.programs.graphical.screenlockers.hyprlock;
in
{
  options.khanelinix.programs.graphical.screenlockers.hyprlock = {
    enable = lib.mkEnableOption "hyprlock in the desktop environment";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
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

        background = [
          {
            monitor = "";
            brightness = "0.817200";
            color = lib.mkDefault "rgba(25, 20, 20, 1.0)";
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
            outer_color = lib.mkDefault catppuccin.colors.crust.rgb;
            inner_color = lib.mkDefault catppuccin.colors.surface2.rgb;
            font_color = lib.mkDefault catppuccin.colors.text.rgb;
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
            path = "${config.khanelinix.user.home}/.face";
            border_color = lib.mkDefault catppuccin.colors.text.rgb;
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
            color = lib.mkDefault catppuccin.colors.text.rgb;
            font_size = 50;
            font_family = lib.mkDefault (osConfig.khanelinix.system.fonts.default or "MonaspaceNeon NF");
            valign = "center";
            halign = "center";
            position = "15, -350";
            shadow_passes = 1;
            rotate = "0.000000";
            shadow_boost = "1.200000";
            shadow_color = lib.mkDefault "rgba(0, 0, 0, 1.0)";
            shadow_size = 3;
          }
          {
            monitor = "";
            text = "<span font_weight=\"ultrabold\"> </span>";
            color = lib.mkDefault catppuccin.colors.text.rgb;
            font_size = 25;
            font_family = lib.mkDefault (osConfig.khanelinix.system.fonts.default or "MonaspaceNeon NF");
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
            color = lib.mkDefault catppuccin.colors.text.rgb;
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
            color = lib.mkDefault catppuccin.colors.text.rgb;
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
            color = lib.mkDefault "rgba(102, 92, 84, .33)";
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
