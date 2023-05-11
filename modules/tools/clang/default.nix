{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.clang;
in {
  options.khanelinix.tools.clang = with types; {
    enable = mkBoolOpt false "Whether or not to enable clang.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      clang
    ];
  };
}
