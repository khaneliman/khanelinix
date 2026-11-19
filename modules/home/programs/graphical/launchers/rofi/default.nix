{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  colors = config.khanelinix.theme.active;
  palette = ''
    * {
      ${lib.concatStringsSep "\n  " (lib.mapAttrsToList (name: color: "${name}: ${color};") colors)}
    }
  '';
  cfg = config.khanelinix.programs.graphical.launchers.rofi;
in
{
  options.khanelinix.programs.graphical.launchers.rofi = {
    enable = lib.mkEnableOption "Rofi in the desktop environment";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ wtype ];

    programs.rofi = {
      # Rofi documentation
      # See: https://github.com/davatorium/rofi/blob/next/doc/rofi.1.markdown
      enable = true;
      settings = {
        font = "MonaspaceNeon NF 14";
        location = 0;
      };
      theme = lib.mkDefault "khanelinix";

      plugins = with pkgs; [
        rofi-calc
        rofi-emoji
        rofi-top
      ];
    };

    xdg.dataFile = {
      "rofi/themes/khanelinix.rasi".text = palette + builtins.readFile ./config/config.rasi;
      "rofi/themes/khanelinix-palette.rasi".text = palette;
    };

    xdg.configFile = {
      "rofi/appmenu" = {
        source = ./config/appmenu;
        recursive = true;
      };
      "rofi/spotlight" = {
        source = ./config/spotlight;
        recursive = true;
      };
    };
  };
}
