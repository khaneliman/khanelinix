{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.cmake;
in {
  options.khanelinix.tools.cmake = with types; {
    enable = mkBoolOpt false "Whether or not to enable cmake.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cmake
    ];
  };
}
