{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.khanelinix.services.skhd;
  userHome = config.users.users.${config.khanelinix.user.name}.home;
in

{
  options.khanelinix.services.skhd = {
    enable = lib.mkEnableOption "skhd log rotation";

    logPaths = {
      stdout = mkOption {
        type = types.str;
        default = "${userHome}/Library/Logs/skhd/skhd.out.log";
        description = "Path to skhd stdout log file";
      };

      stderr = mkOption {
        type = types.str;
        default = "${userHome}/Library/Logs/skhd/skhd.err.log";
        description = "Path to skhd stderr log file";
      };
    };
  };

  config = mkIf cfg.enable {
    system.newsyslog.files.skhd = [
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
