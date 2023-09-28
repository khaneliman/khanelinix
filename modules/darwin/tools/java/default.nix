{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.java;
in
{
  options.khanelinix.tools.java = {
    enable = mkBoolOpt false "Whether or not to enable Java.";
  };

  # TODO: remove module
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jdk
    ];
  };
}
