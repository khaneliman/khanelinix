{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.pitivi;
in
{
  options.khanelinix.apps.pitivi = with types; {
    enable = mkBoolOpt false "Whether or not to enable Pitivi.";
  };

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ pitivi ]; };
}
