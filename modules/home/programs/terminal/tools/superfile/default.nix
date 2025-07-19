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
      settings = {
        # transparent_background = false;
        theme = "catppuccin";
      };
    };
  };
}
