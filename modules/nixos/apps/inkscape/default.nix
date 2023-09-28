{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.apps.inkscape;
in
{
  options.khanelinix.apps.inkscape = {
    enable = mkBoolOpt false "Whether or not to enable Inkscape.";
  };
  # TODO: remove module
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inkscape-with-extensions
      google-fonts
    ];
  };
}
