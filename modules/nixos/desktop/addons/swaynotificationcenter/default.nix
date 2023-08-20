{ options
, config
, lib
, pkgs
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
      configFile."swaync/" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource ./config/.;
        };

        recursive = true;
      };
    };
  };
}
