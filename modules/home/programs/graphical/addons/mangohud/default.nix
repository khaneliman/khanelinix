{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf literalExpression;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.mangohud;
in
{
  options.khanelinix.programs.graphical.mangohud = {
    enable = mkBoolOpt false "Whether or not to enable mangohud.";
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
