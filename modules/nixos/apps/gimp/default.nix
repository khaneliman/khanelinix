{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.gimp;
in
{
  options.khanelinix.apps.gimp = {
    enable = mkBoolOpt false "Whether or not to enable Gimp.";
  };
  # TODO: remove module

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ gimp ]; };
}
