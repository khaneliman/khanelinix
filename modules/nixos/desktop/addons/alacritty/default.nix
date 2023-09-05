{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
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
