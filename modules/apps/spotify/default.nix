{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.spotify;
in
{
  options.khanelinix.apps.spotify = with types; {
    enable = mkBoolOpt false "Whether or not to enable support for spotify.";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      spotify
    ];
  };
}
