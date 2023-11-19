{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.apps.caprine;
in
{
  options.khanelinix.apps.caprine = {
    enable = mkEnableOption "caprine";
  };

  config = mkIf cfg.enable {
    xdg.configFile = mkIf pkgs.stdenv.isLinux {
      "Caprine/custom.css".source = ./custom.css;
    };

    home.file = mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/Caprine/custom.css".source = ./custom.css;
    };
  };
}
