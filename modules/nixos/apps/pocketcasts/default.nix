{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.pocketcasts;
in
{
  options.khanelinix.apps.pocketcasts = {
    enable = mkBoolOpt false "Whether or not to enable Pocketcasts.";
  };

  # TODO: remove module
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs.khanelinix; [ pocketcasts ];
  };
}
