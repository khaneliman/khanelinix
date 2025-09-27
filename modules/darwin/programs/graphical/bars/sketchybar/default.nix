{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.khanelinix.programs.graphical.bars.sketchybar;
  userHome = config.users.users.${config.khanelinix.user.name}.home;
in

{
  options.khanelinix.programs.graphical.bars.sketchybar = {
    enable = lib.mkEnableOption "sketchybar log rotation";

    logPaths = {
      stdout = mkOption {
        type = types.str;
        default = "${userHome}/Library/Logs/sketchybar/sketchybar.out.log";
        description = "Path to sketchybar stdout log file";
      };

      stderr = mkOption {
        type = types.str;
        default = "${userHome}/Library/Logs/sketchybar/sketchybar.err.log";
        description = "Path to sketchybar stderr log file";
      };
    };
  };

  config = mkIf cfg.enable {
    system.newsyslog.files.sketchybar = [
      {
        logfilename = cfg.logPaths.stdout;
        mode = "644";
        owner = config.khanelinix.user.name;
        group = "staff";
        count = 7;
        size = "1000";
        flags = [
          "Z"
          "C"
        ];
      }
      {
        logfilename = cfg.logPaths.stderr;
        mode = "644";
        owner = config.khanelinix.user.name;
        group = "staff";
        count = 7;
        size = "1000";
        flags = [
          "Z"
          "C"
        ];
      }
    ];
  };
}
