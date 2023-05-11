{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.thunderbird;
in
{
  options.khanelinix.apps.thunderbird = with types; {
    enable = mkBoolOpt false "Whether or not to enable thunderbird.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ thunderbird davmail ]; };
}
