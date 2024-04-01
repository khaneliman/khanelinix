{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.bat;
in
{
  options.khanelinix.tools.bat = {
    enable = mkBoolOpt false "Whether or not to enable bat.";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;

      config = {
        style = "auto,header-filesize";
      };

      extraPackages = with pkgs.bat-extras; [
        batdiff
        batgrep
        batman
        batpipe
        batwatch
        prettybat
      ];
    };

    home.shellAliases = {
      cat = "bat";
    };
  };
}
