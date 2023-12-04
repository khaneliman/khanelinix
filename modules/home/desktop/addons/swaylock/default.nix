{ config
, lib
, inputs
, options
, pkgs
, system
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.khanelinix.desktop.addons.swaylock;
in
{
  options.khanelinix.desktop.addons.swaylock = {
    enable =
      mkBoolOpt false "Whether to enable swaylock in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.swaylock = {
      enable = true;

      package = nixpkgs-wayland.packages.${system}.swaylock;
      settings = {
        # ignore-empty-password = true;
        # disable-caps-lock-text = true;
        font = "MonaspiceAr Nerd Font";
        # grace = 300;

        image = "${pkgs.khanelinix.wallpapers}/share/wallpapers/flatppuccin_macchiato.png";

        # fade-in = "0.2";

        # effect-blur = "10x2";
        # effect-scale = "0.1";

        # indicator = true;
        # indicator-radius = 240;
        # indicator-thickness = 20;
        # indicator-caps-lock = true;

        key-hl-color = "a6da95";
        bs-hl-color = "f4dbd6";
        caps-lock-key-hl-color = "a6da95";
        caps-lock-bs-hl-color = "f4dbd6";

        separator-color = "00000000";

        inside-color = "00000000";
        inside-clear-color = "00000000";
        inside-caps-lock-color = "00000000";
        inside-ver-color = "00000000";
        inside-wrong-color = "00000000";

        ring-color = "b7bdf8";
        ring-clear-color = "f4dbd6";
        ring-caps-lock-color = "f5a97f";
        ring-ver-color = "8aadf4";
        ring-wrong-color = "ee99a0";

        line-color = "00000000";
        line-clear-color = "00000000";
        line-caps-lock-color = "00000000";
        line-ver-color = "00000000";
        line-wrong-color = "00000000";

        text-color = "cad3f5";
        text-clear-color = "f4dbd6";
        text-caps-lock-color = "f5a97f";
        text-ver-color = "8aadf4";
        text-wrong-color = "ee99a0";

        # debug = true;
      };
    };
  };
}
