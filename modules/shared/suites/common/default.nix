{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
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
