{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.television;
in
{
  options.khanelinix.programs.terminal.tools.television = {
    enable = lib.mkEnableOption "television";
  };

  config = mkIf cfg.enable {
    programs.television = {
      enable = true;

      settings = {
        ui = lib.mkMerge [
          {
            use_nerd_font_icons = true;
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
  };
}
