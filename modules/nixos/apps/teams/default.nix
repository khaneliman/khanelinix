{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.teams;
in
{
  options.khanelinix.apps.teams = {
    enable = mkBoolOpt false "Whether or not to enable teams.";
  };
  # TODO: remove module
  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ teams ]; };
}
