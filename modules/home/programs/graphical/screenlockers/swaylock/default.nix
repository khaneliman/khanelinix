{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.programs.graphical.screenlockers.swaylock;
  wallpaperPath = name: lib.khanelinix.theme.wallpaperPath { inherit config pkgs name; };
in
{
  options.khanelinix.programs.graphical.screenlockers.swaylock = {
    enable = lib.mkEnableOption "swaylock in the desktop environment";
  };

  config = mkIf cfg.enable {
    programs.swaylock = {
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

        key-hl-color = mkDefault "#8aadf4";
        bs-hl-color = mkDefault "#ed8796";
        caps-lock-key-hl-color = mkDefault "#f5a97f";
        caps-lock-bs-hl-color = mkDefault "#ed8796";

        separator-color = mkDefault "#181926";

        inside-color = mkDefault "#24273a";
        inside-clear-color = mkDefault "#24273a";
        inside-caps-lock-color = mkDefault "#24273a";
        inside-ver-color = mkDefault "#24273a";
        inside-wrong-color = mkDefault "#24273a";

        ring-color = mkDefault "#1e2030";
        ring-clear-color = mkDefault "#8aadf4";
        ring-caps-lock-color = mkDefault "231f20D9";
        ring-ver-color = mkDefault "#1e2030";
        ring-wrong-color = mkDefault "#ed8796";

        line-color = mkDefault "#8aadf4";
        line-clear-color = mkDefault "#8aadf4";
        line-caps-lock-color = mkDefault "#f5a97f";
        line-ver-color = mkDefault "#181926";
        line-wrong-color = mkDefault "#ed8796";

        text-color = mkDefault "#8aadf4";
        text-clear-color = mkDefault "#24273a";
        text-caps-lock-color = mkDefault "#f5a97f";
        text-ver-color = mkDefault "#24273a";
        text-wrong-color = mkDefault "#24273a";

        debug = true;
      };
    };
  };
}
