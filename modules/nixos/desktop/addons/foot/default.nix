{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.desktop.addons.foot;
in
{
  options.khanelinix.desktop.addons.foot = {
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
