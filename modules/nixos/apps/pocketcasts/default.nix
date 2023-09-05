{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.pocketcasts;
in
{
  options.khanelinix.apps.pocketcasts = with types; {
    enable = mkBoolOpt false "Whether or not to enable Pocketcasts.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs.khanelinix; [ pocketcasts ];
  };
}
