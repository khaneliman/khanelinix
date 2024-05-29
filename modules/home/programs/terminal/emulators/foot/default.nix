{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (lib.strings) removePrefix;

  cfg = config.${namespace}.programs.terminal.emulators.foot;
  catppuccin = import (lib.snowfall.fs.get-file "modules/home/theme/catppuccin/colors.nix");
in
{
  options.${namespace}.programs.terminal.emulators.foot = {
    enable = mkBoolOpt false "Whether or not to enable foot.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ libsixel ];

    programs.foot = {
      enable = true;
      package = pkgs.foot;

      server.enable = false;

      settings = {
        main = {
          # window settings
          app-id = "foot";
          locked-title = "no";
          pad = "16x16 center";
          shell = "zsh";
          term = "xterm-256color";
          title = "foot";

          # notifications
          notify = "notify-send -a \${app-id} -i \${app-id} \${title} \${body}";
          selection-target = "clipboard";

          # font and font rendering
          dpi-aware = false; # this looks more readable on a laptop, but it's unreasonably large
          font = "MonaspiceKr Nerd Font:size=12";
          font-bold = "MonaspiceKr Nerd Font:size=12";
          vertical-letter-offset = "-0.90";
        };

        scrollback = {
          lines = 10000;
          multiplier = 3;
        };

        tweak = {
          font-monospace-warn = "no"; # reduces startup time
          sixel = "yes";
        };

        cursor = {
          beam-thickness = 2;
          style = "beam";
        };

        mouse = {
          hide-when-typing = "yes";
        };

        url = {
          label-letters = "sadfjklewcmpgh";
          launch = "xdg-open \${url}";
          osc8-underline = "url-mode";
          protocols = "http, https, ftp, ftps, file";
          uri-characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.,~:;/?#@!$&%*+=\"'()[]";
        };

        colors = {
          alpha = "0.85";

          foreground = "${(removePrefix "#") catppuccin.colors.text.hex}";
          background = "${(removePrefix "#") catppuccin.colors.base.hex}";

          regular0 = "${(removePrefix "#") catppuccin.colors.surface1.hex}";
          regular1 = "${(removePrefix "#") catppuccin.colors.red.hex}";
          regular2 = "${(removePrefix "#") catppuccin.colors.green.hex}";
          regular3 = "${(removePrefix "#") catppuccin.colors.yellow.hex}";
          regular4 = "${(removePrefix "#") catppuccin.colors.blue.hex}";
          regular5 = "${(removePrefix "#") catppuccin.colors.pink.hex}";
          regular6 = "${(removePrefix "#") catppuccin.colors.teal.hex}";
          regular7 = "${(removePrefix "#") catppuccin.colors.subtext0.hex}";

          bright0 = "${(removePrefix "#") catppuccin.colors.surface2.hex}";
          bright1 = "${(removePrefix "#") catppuccin.colors.red.hex}";
          bright2 = "${(removePrefix "#") catppuccin.colors.green.hex}";
          bright3 = "${(removePrefix "#") catppuccin.colors.yellow.hex}";
          bright4 = "${(removePrefix "#") catppuccin.colors.blue.hex}";
          bright5 = "${(removePrefix "#") catppuccin.colors.pink.hex}";
          bright6 = "${(removePrefix "#") catppuccin.colors.teal.hex}";
          bright7 = "${(removePrefix "#") catppuccin.colors.subtext0.hex}";
        };
      };
    };
  };
}
