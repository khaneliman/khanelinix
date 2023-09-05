{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.cli-apps.wine;
in
{
  options.khanelinix.cli-apps.wine = with types; {
    enable = mkBoolOpt false "Whether or not to enable Wine.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # winePackages.waylandFull
      winetricks
      wine64Packages.waylandFull
    ];
  };
}
