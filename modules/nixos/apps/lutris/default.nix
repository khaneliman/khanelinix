{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.lutris;
in
{
  options.khanelinix.apps.lutris = {
    enable = mkBoolOpt false "Whether or not to enable Lutris.";
  };

  # TODO: remove module
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lutris
    ];
  };
}
