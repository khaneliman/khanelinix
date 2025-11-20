{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.screenlockers.swaylock;
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

        image = "${pkgs.khanelinix.wallpapers}/share/wallpapers/flatppuccin_macchiato.png";

        fade-in = "0.2";

        effect-blur = "10x2";
        effect-scale = "0.1";

        indicator = true;
        indicator-radius = 240;
        indicator-thickness = 20;
        indicator-caps-lock = true;

        key-hl-color = "#8aadf4";
        bs-hl-color = "#ed8796";
        caps-lock-key-hl-color = "#f5a97f";
        caps-lock-bs-hl-color = "#ed8796";

        separator-color = "#181926";

        inside-color = "#24273a";
        inside-clear-color = "#24273a";
        inside-caps-lock-color = "#24273a";
        inside-ver-color = "#24273a";
        inside-wrong-color = "#24273a";

        ring-color = "#1e2030";
        ring-clear-color = "#8aadf4";
        ring-caps-lock-color = "231f20D9";
        ring-ver-color = "#1e2030";
        ring-wrong-color = "#ed8796";

        line-color = "#8aadf4";
        line-clear-color = "#8aadf4";
        line-caps-lock-color = "#f5a97f";
        line-ver-color = "#181926";
        line-wrong-color = "#ed8796";

        text-color = "#8aadf4";
        text-clear-color = "#24273a";
        text-caps-lock-color = "#f5a97f";
        text-ver-color = "#24273a";
        text-wrong-color = "#24273a";

        debug = true;
      };
    };
  };
}
