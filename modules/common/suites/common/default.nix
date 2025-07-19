{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = {
    enable = lib.mkEnableOption "common configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      coreutils
      curl
      fd
      file
      findutils
      killall
      lsof
      pciutils
      tldr
      unzip
      wget
      xclip
    ];
  };
}
