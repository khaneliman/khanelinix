{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.tray-tui;
in
{
  options.khanelinix.programs.terminal.tools.tray-tui = {
    enable = lib.mkEnableOption "tray-tui";
  };

  config = mkIf cfg.enable {
    programs.tray-tui = {
      enable = true;
      package = pkgs.tray-tui;
    };
  };
}
