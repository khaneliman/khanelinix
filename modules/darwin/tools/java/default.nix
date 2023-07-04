{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.java;
in {
  options.khanelinix.tools.java = with types; {
    enable = mkBoolOpt false "Whether or not to enable Java.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jdk
    ];
  };
}
