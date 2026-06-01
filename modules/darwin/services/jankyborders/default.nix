{ config, lib, ... }:

let
  inherit (lib)
    hasSuffix
    mkIf
    mkOption
    removeSuffix
    types
    ;

  cfg = config.khanelinix.services.jankyborders;
  userHome = config.users.users.${config.khanelinix.user.name}.home;
  cfgLogErrPath =
    if hasSuffix ".out.log" cfg.logPath then
      "${removeSuffix ".out.log" cfg.logPath}.err.log"
    else
      "${cfg.logPath}.err";
in

{
  options.khanelinix.services.jankyborders = {
    enable = lib.mkEnableOption "jankyborders log rotation";

    logPath = mkOption {
      type = types.str;
      default = "${userHome}/Library/Logs/borders/borders.out.log";
      description = "Path to jankyborders stdout log file";
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
        size = "2048";
        flags = [
          "Z"
          "C"
        ];
      }
      {
        logfilename = cfgLogErrPath;
        mode = "644";
        owner = config.khanelinix.user.name;
        group = "staff";
        count = 7;
        size = "2048";
        flags = [
          "Z"
          "C"
        ];
      }
    ];
  };
}
