{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.pitivi;
in
{
  options.khanelinix.apps.pitivi = {
    enable = mkBoolOpt false "Whether or not to enable Pitivi.";
  };
  # TODO: remove module

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ pitivi ]; };
}
