{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.gnumake;
in {
  options.khanelinix.tools.gnumake = with types; {
    enable = mkBoolOpt false "Whether or not to enable gnumake.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnumake
    ];
  };
}
