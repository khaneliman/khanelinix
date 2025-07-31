{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.system.logging;
in

{
  imports = [
    ./newsyslog.nix
  ];

  options.khanelinix.system.logging = {
    enable = mkEnableOption "system logging configuration";
  };

  config = mkIf cfg.enable {
    system.newsyslog = {
      enable = true;
    };
  };
}
