{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.swaynotificationcenter;
in
{
  options.khanelinix.desktop.addons.swaynotificationcenter = with types; {
    enable =
      mkBoolOpt false "Whether to enable swaynotificationcenter in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ swaynotificationcenter libnotify ];

    khanelinix.home = {
      configFile = with inputs; {
        "swaync/".source = dotfiles.outPath + "/dots/linux/hyprland/home/.config/swaync";
      };
    };
  };
}
