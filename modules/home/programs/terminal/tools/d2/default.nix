{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.d2;
in
{
  options.khanelinix.programs.terminal.tools.d2 = {
    enable = lib.mkEnableOption "D2 architecture diagrams";
  };

  config = lib.mkIf cfg.enable {
    home = {
      # Image support follows the upstream default, which needs libdrm and is
      # therefore Linux only
      packages = [ pkgs.d2 ];

      sessionVariables.D2_LAYOUT = "elk";

      shellAliases = {
        d2-check = "d2 fmt --check";
        d2-watch = "d2 --watch";
      };
    };
  };
}
