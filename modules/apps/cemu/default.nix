{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.cemu;
in
{
  options.khanelinix.apps.cemu = with types; {
    enable = mkBoolOpt false "Whether or not to enable cemu.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ cemu ];
  };
}
