{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf literalExpression;

  cfg = config.khanelinix.programs.graphical.mangohud;
in
{
  options.khanelinix.programs.graphical.mangohud = {
    enable = lib.mkEnableOption "mangohud";
  };

  config = mkIf cfg.enable {
    programs.mangohud = {
      enable = true;
      package = pkgs.mangohud;
      enableSessionWide = true;
      settings = literalExpression ''
        {
          output_folder = ~/Documents/mangohud/;
          full = true;
        }
      '';
    };
  };
}
