{ config, lib, ... }:
let
  cfg = config.khanelinix.programs.terminal.tools.khal;
in
{
  options.khanelinix.programs.terminal.tools.khal = {
    enable = lib.mkEnableOption "khal";
  };

  config = lib.mkIf cfg.enable {
    programs.khal = {
      enable = true;

      locale = {
        dateformat = "%Y-%m-%d";
        longdateformat = "%Y-%m-%d";
        timeformat = "%I:%M %p";
        datetimeformat = "%Y-%m-%d %I:%M %p";
        longdatetimeformat = "%Y-%m-%d %I:%M %p";
      };

      settings = {
        default = {
          highlight_event_days = true;
          show_all_days = false;
        };
      };
    };
  };
}
