{ config
, lib
, options
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
        theme = "catppuccin-macchiato";
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

      themes = {
        catppuccin-macchiato = {
          src = pkgs.catppuccin;
          file = "/bat/Catppuccin-macchiato.tmTheme";
        };
      };
    };

    home.shellAliases = {
      cat = "bat";
    };
  };
}
