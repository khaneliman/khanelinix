{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.teams;
in
{
  options.khanelinix.apps.teams = with types; {
    enable = mkBoolOpt false "Whether or not to enable teams.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ teams ]; };
}
