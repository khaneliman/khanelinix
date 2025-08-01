{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.khanelinix.programs.terminal.tools.nh;
  userHome = config.users.users.${config.khanelinix.user.name}.home;
in

{
  options.khanelinix.programs.terminal.tools.nh = {
    enable = lib.mkEnableOption "nh log rotation";

    logPaths = {
      stdout = mkOption {
        type = types.str;
        default = "${userHome}/Library/Logs/nh/nh.out.log";
        description = "Path to nh stdout log file";
      };

      stderr = mkOption {
        type = types.str;
        default = "${userHome}/Library/Logs/nh/nh.err.log";
        description = "Path to nh stderr log file";
      };
    };
  };

  config = mkIf cfg.enable {
    system.newsyslog.files.nh-clean = [
      {
        logfilename = cfg.logPaths.stdout;
        mode = "644";
        count = 7;
        size = "1M";
        flags = [
          "Z"
          "C"
        ];
      }
      {
        logfilename = cfg.logPaths.stderr;
        mode = "644";
        count = 7;
        size = "1M";
        flags = [
          "Z"
          "C"
        ];
      }
    ];
  };
}
