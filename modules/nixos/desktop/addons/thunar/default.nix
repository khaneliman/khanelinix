{ options
, config
, lib
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.desktop.addons.thunar;
in
{
  options.khanelinix.desktop.addons.thunar = with types; {
    enable = mkBoolOpt false "Whether to enable the xfce file manager.";
  };

  config = mkIf cfg.enable {
    programs.thunar = {
      enable = true;
    };
  };
}
