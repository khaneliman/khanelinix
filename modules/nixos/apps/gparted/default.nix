{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.gparted;
in
{
  options.khanelinix.apps.gparted = {
    enable = mkBoolOpt false "Whether or not to enable gparted.";
  };
  # TODO: remove module

  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ gparted ]; };
}
