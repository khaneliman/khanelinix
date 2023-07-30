{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.mangohud;
in
{
  options.khanelinix.apps.mangohud = with types; {
    enable = mkBoolOpt false "Whether or not to enable mangohud.";
  };

  config = mkIf cfg.enable {
    # environment.systemPackages = with pkgs; [mangohud];
    khanelinix.home.extraOptions = {
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
  };
}
