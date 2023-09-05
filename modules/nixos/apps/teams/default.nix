{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.teams;
in
{
  options.khanelinix.apps.teams = with types; {
    enable = mkBoolOpt false "Whether or not to enable teams.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ teams ]; };
}
