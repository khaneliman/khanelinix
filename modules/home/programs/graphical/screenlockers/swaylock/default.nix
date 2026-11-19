{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.programs.graphical.screenlockers.swaylock;
  colors = config.khanelinix.theme.active;
  wallpaperPath = name: lib.khanelinix.theme.wallpaperPath { inherit config pkgs name; };
in
{
  options.khanelinix.programs.graphical.screenlockers.swaylock = {
    enable = lib.mkEnableOption "swaylock in the desktop environment";
  };

  config = mkIf cfg.enable {
    programs.swaylock = {
      # Swaylock documentation
      # See: https://github.com/swaywm/swaylock
      enable = true;
      package = pkgs.swaylock-effects;

      settings = {
        ignore-empty-password = true;
        disable-caps-lock-text = true;
        font = "MonaspaceArgon NF";
        grace = 300;

        clock = true;
        timestr = "%R";
        datestr = "%a, %e of %B";

        image = mkDefault (wallpaperPath config.khanelinix.theme.wallpaper.lock);

        fade-in = "0.2";

        effect-blur = "10x2";
        effect-scale = "0.1";

        indicator = true;
        indicator-radius = 240;
        indicator-thickness = 20;
        indicator-caps-lock = true;

        debug = true;
      }
      // lib.optionalAttrs (config.khanelinix.theme ? active) {
        key-hl-color = mkDefault colors.accent;
        bs-hl-color = mkDefault colors.danger;
        caps-lock-key-hl-color = mkDefault colors.warning;
        caps-lock-bs-hl-color = mkDefault colors.danger;

        separator-color = mkDefault colors.shadow;

        inside-color = mkDefault colors.background;
        inside-clear-color = mkDefault colors.background;
        inside-caps-lock-color = mkDefault colors.background;
        inside-ver-color = mkDefault colors.background;
        inside-wrong-color = mkDefault colors.background;

        ring-color = mkDefault colors.border;
        ring-clear-color = mkDefault colors.accent;
        ring-caps-lock-color = mkDefault colors.warning;
        ring-ver-color = mkDefault colors.border;
        ring-wrong-color = mkDefault colors.danger;

        line-color = mkDefault colors.accent;
        line-clear-color = mkDefault colors.accent;
        line-caps-lock-color = mkDefault colors.warning;
        line-ver-color = mkDefault colors.shadow;
        line-wrong-color = mkDefault colors.danger;

        text-color = mkDefault colors.foreground;
        text-clear-color = mkDefault colors.accent;
        text-caps-lock-color = mkDefault colors.warning;
        text-ver-color = mkDefault colors.foreground;
        text-wrong-color = mkDefault colors.danger;
      };
    };
  };
}
