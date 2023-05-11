{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.kitty;
in
{
  options.khanelinix.desktop.addons.kitty = with types; {
    enable = mkBoolOpt false "Whether to enable kitty.";
  };

  config = mkIf cfg.enable {
    khanelinix.desktop.addons.term = {
      enable = true;
      pkg = pkgs.kitty;
    };

    khanelinix.home = {
      configFile = with inputs; {
        "kitty/".source = dotfiles.outPath + "/dots/shared/home/.config/kitty";
      };
    };
  };
}
