{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.wdisplays;
in
{
  options.khanelinix.desktop.addons.wdisplays = with types; {
    enable =
      mkBoolOpt false "Whether to enable wdisplays in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ wdisplays ];
  };
}
