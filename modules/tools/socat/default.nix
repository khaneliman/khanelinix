{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.socat;
in {
  options.khanelinix.tools.socat = with types; {
    enable = mkBoolOpt false "Whether or not to enable socat.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      socat
    ];
  };
}
