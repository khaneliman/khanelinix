{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
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
  };
}
