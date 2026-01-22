{
  config,
  pkgs,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.emulators.foot;
  fontCfg = config.khanelinix.fonts;
in
{
  options.khanelinix.programs.terminal.emulators.foot = {
    enable = lib.mkEnableOption "foot";
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
          pad = "12x12 center";
          shell = "zsh";
          term = "xterm-256color";
          title = "foot";

          # notifications
          notify = "notify-send -a \${app-id} -i \${app-id} \${title} \${body}";
          selection-target = "clipboard";

          # font and font rendering
          dpi-aware = lib.mkDefault false; # this looks more readable on a laptop, but it's unreasonably large
          font = "${fontCfg.monaspace.families.krypton}:size=13";
          font-bold = "${fontCfg.monaspace.families.krypton}:size=13";
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
          alpha = lib.mkDefault "0.85";
        };
      };
    };
  };
}
