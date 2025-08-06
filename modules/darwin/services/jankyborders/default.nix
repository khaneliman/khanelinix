{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.khanelinix.services.jankyborders;
  userHome = config.users.users.${config.khanelinix.user.name}.home;
in

{
  options.khanelinix.services.jankyborders = {
    enable = lib.mkEnableOption "jankyborders log rotation";

    logPath = mkOption {
      type = types.str;
      default = "${userHome}/Library/Logs/jankyborders.log";
      description = "Path to jankyborders log file";
    };
  };

  config = mkIf cfg.enable {
    system.newsyslog.files.jankyborders = [
      {
        logfilename = cfg.logPath;
        mode = "644";
        owner = config.khanelinix.user.name;
        group = "staff";
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
