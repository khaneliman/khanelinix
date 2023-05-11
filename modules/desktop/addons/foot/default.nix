{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.foot;
in {
  options.khanelinix.desktop.addons.foot = with types; {
    enable = mkBoolOpt false "Whether to enable the foot.";
  };

  config = mkIf cfg.enable {
    khanelinix.desktop.addons.term = {
      enable = true;
      pkg = pkgs.foot;
    };

    khanelinix.home.configFile."foot/foot.ini".source = ./foot.ini;
  };
}
