{ config
, inputs
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) hyprlock;

  cfg = config.khanelinix.desktop.addons.hyprlock;
in
{
  imports = [ hyprlock.homeManagerModules.default ];

  options.khanelinix.desktop.addons.hyprlock = {
    enable =
      mkBoolOpt false "Whether to enable hyprlock in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      # package = pkgs.hyprlock;

      general = {
        grace = 300;
      };

      input-fields = [
        {
          outer_color = "rgb(24, 25, 38)";
          inner_color = "rgb(91, 96, 120)";
          font_color = "rgb(202, 211, 245)";
          halign = "center";
          valign = "bottom";
        }
      ];

      labels = [
        {
          text = "$TIME";
          color = "rgb(24, 25, 38)";
          font_family = config.khanelinix.system.fonts.default;
          font_size = 72;
          halign = "center";
          valign = "center";
        }
        {
          text = "Welcome back, $USER!";
          color = "rgb(237, 135, 150)";
          font_family = config.khanelinix.system.fonts.default;
          font_size = 72;
          halign = "center";
          valign = "top";
          position = {
            y = -20;
          };
        }
      ];

      backgrounds = [
        {
          path = "${pkgs.khanelinix.wallpapers}/share/wallpapers/flatppuccin_macchiato.png";
        }
      ];
    };
  };
}
