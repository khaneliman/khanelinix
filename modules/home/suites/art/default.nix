{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.suites.art;
in
{
  options.khanelinix.suites.art = {
    enable = mkBoolOpt false "Whether or not to enable art configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      blender
      gimp
      inkscape-with-extensions
    ];
  };
}
