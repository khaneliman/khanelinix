{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.vlc;
in
{
  options.khanelinix.apps.vlc = {
    enable = mkBoolOpt false "Whether or not to enable vlc.";
  };

  # TODO: remove module
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ vlc ];
  };
}
