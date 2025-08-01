{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.khanelinix.services.skhd;
  userHome = config.users.users.${config.khanelinix.user.name}.home;
in

{
  options.khanelinix.services.skhd = {
    enable = lib.mkEnableOption "skhd log rotation";

    logPath = mkOption {
      type = types.str;
      default = "${userHome}/Library/Logs/skhd.log";
      description = "Path to skhd log file";
    };
  };

  config = mkIf cfg.enable {
    system.newsyslog.files.skhd = [
      {
        logfilename = cfg.logPath;
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
