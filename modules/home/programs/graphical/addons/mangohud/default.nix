{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf literalExpression;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.mangohud;
in
{
  options.${namespace}.programs.graphical.mangohud = {
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
