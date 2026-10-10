{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.logrotate;
in
{
  options.khanelinix.services.logrotate = {
    enable = lib.mkEnableOption "logrotate";
  };

  config = mkIf cfg.enable {
    services.logrotate.settings.header = {
      # general
      global = true;
      dateext = true;
      dateformat = "-%Y-%m-%d";
      nomail = true;
      missingok = true;
      copytruncate = true;

      # rotation frequency
      priority = 1;
      frequency = "weekly";
      rotate = 7; # Keep seven rotated logs.
      minage = 7; # avoid removing logs that are less than 7 days old

      # compression
      compress = true; # lets compress logs to save space
      compresscmd = "${lib.getExe' pkgs.zstd "zstd"}";
      compressoptions = "-10";
      compressext = "zst";
      uncompresscmd = "${lib.getExe' pkgs.zstd "unzstd"}";
    };
  };
}
