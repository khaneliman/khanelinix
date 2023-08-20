{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.alacritty;
in
{
  options.khanelinix.desktop.addons.alacritty = with types; {
    enable = mkBoolOpt false "Whether to enable alacritty.";
  };

  config = mkIf cfg.enable {
    khanelinix.desktop.addons.term = {
      enable = true;
      pkg = pkgs.alacritty;
    };
  };
}
