{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.superfile;
in
{
  options.khanelinix.programs.terminal.tools.superfile = {
    enable = lib.mkEnableOption "superfile";
  };

  config = mkIf cfg.enable {
    programs.superfile = {
      enable = true;
      settings = lib.mkMerge [
        {
          # transparent_background = false;
        }
        (lib.mkIf config.khanelinix.theme.catppuccin.enable {
          theme = "catppuccin";
        })
        (lib.mkIf config.khanelinix.theme.nord.enable {
          theme = "nord";
        })
        (lib.mkIf config.khanelinix.theme.tokyonight.enable {
          theme = "tokyonight";
        })
      ];
    };
  };
}
