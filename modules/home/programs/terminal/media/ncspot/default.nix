{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.media.ncspot;
in
{
  options.khanelinix.programs.terminal.media.ncspot = {
    enable = mkEnableOption "ncspot";
  };

  config = mkIf cfg.enable {
    programs.ncspot = {
      enable = true;

      settings = {
        theme = {
          background = "#24273A";
          primary = "#CAD3F5";
          secondary = "#1E2030";
          title = "#8AADF4";
          playing = "#8AADF4";
          playing_selected = "#B7BDF8";
          playing_bg = "#181926";
          highlight = "#C6A0F6";
          highlight_bg = "#494D64";
          error = "#CAD3F5";
          error_bg = "#ED8796";
          statusbar = "#181926";
          statusbar_progress = "#CAD3F5";
          statusbar_bg = "#8AADF4";
          cmdline = "#CAD3F5";
          cmdline_bg = "#181926";
          search_match = "#f5bde6";
        };
      };
    };
  };
}
