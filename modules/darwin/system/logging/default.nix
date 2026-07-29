{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.system.logging;
in

{
  options.khanelinix.system.logging = {
    enable = mkEnableOption "system logging configuration";
  };

  config = mkIf cfg.enable {
    system.newsyslog = {
      enable = true;
    };
  };
}
