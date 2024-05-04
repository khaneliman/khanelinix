{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.system.logrotate;
in
{
  options.khanelinix.system.logrotate = {
    enable = mkBoolOpt false "Whether or not to configure logrotate.";
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
      rotate = 7; # special value, means every 7 days
      minage = 7; # avoid removing logs that are less than 7 days old

      # compression
      compress = true; # lets compress logs to save space
      compresscmd = "${lib.getExe' pkgs.zstd "zstd"}";
      compressoptions = " -Xcompression-level 10";
      compressext = "zst";
      uncompresscmd = "${lib.getExe' pkgs.zstd "unzstd"}";
    };
  };
}
