{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  catppuccin = import ../../theme/catppuccin.nix;

  cfg = config.khanelinix.desktop.addons.hyprlock;
in
{
  options.khanelinix.desktop.addons.hyprlock = {
    enable = mkBoolOpt false "Whether to enable hyprlock in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      package = pkgs.hyprlock;

      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 300;
        no_fade_in = false;
      };

      backgrounds = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-fields = [
        {
          size = {
            width = 200;
            height = 50;
          };
          position = {
            x = 0;
            y = -80;
          };
          outline_thickness = 5;
          dots_center = true;
          outer_color = catppuccin.colors.crust.rgb;
          inner_color = catppuccin.colors.surface2.rgb;
          font_color = catppuccin.colors.text.rgb;
          fade_on_empty = false;
          placeholder_text = "<span foreground=\"##cad3f5\">Password...</span>";
          shadow_passes = 2;
        }
      ];

      images = [
        {
          size = 120;
          position = {
            x = 0;
            y = 45;
          };
          path = "/home/${config.snowfallorg.user.name}/.face";
          border_color = catppuccin.colors.text.rgb;
          border_size = 5;
          halign = "center";
          valign = "center";
          shadow_passes = 1;
        }
      ];

      labels = [
        {
          text = "<span font_weight=\"ultrabold\">$TIME</span>";
          color = catppuccin.colors.text.rgb;
          font_size = 100;
          font_family = config.khanelinix.system.fonts.default;
          valign = "center";
          halign = "center";
          position = {
            x = 0;
            y = 330;
          };
          shadow_passes = 2;
        }
        {
          text = "<span font_weight=\"bold\"> $USER</span>";
          color = catppuccin.colors.text.rgb;
          font_size = 25;
          font_family = config.khanelinix.system.fonts.default;
          valign = "top";
          halign = "left";
          position = {
            x = 10;
            y = 0;
          };
          shadow_passes = 1;
        }
        {
          text = "<span font_weight=\"ultrabold\">󰌾 </span>";
          color = catppuccin.colors.text.rgb;
          font_size = 50;
          font_family = config.khanelinix.system.fonts.default;
          valign = "center";
          halign = "center";
          position = {
            x = 15;
            y = -350;
          };
          shadow_passes = 1;
        }
        {
          text = "<span font_weight=\"bold\">Locked</span>";
          color = catppuccin.colors.text.rgb;
          font_size = 25;
          font_family = config.khanelinix.system.fonts.default;
          valign = "center";
          halign = "center";
          position = {
            x = 0;
            y = -430;
          };
          shadow_passes = 1;
        }
        {
          text = "cmd[update:120000] echo \"<span font_weight='bold'>$(date +'%a %d %B')</span>\"";
          color = catppuccin.colors.text.rgb;
          font_size = 30;
          font_family = config.khanelinix.system.fonts.default;
          valign = "center";
          halign = "center";
          position = {
            x = 0;
            y = 210;
          };
          shadow_passes = 1;
        }
        {
          text = "<span font_weight=\"ultrabold\"> </span>";
          color = catppuccin.colors.text.rgb;
          font_size = 25;
          font_family = config.khanelinix.system.fonts.default;
          valign = "bottom";
          halign = "right";
          position = {
            x = 5;
            y = 8;
          };
          shadow_passes = 1;
        }
      ];
    };
  };
}
