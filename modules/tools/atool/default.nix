{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.atool;
in {
  options.khanelinix.tools.atool = with types; {
    enable = mkBoolOpt false "Whether or not to enable atool.";
  };

  config =
    mkIf cfg.enable {environment.systemPackages = with pkgs; [atool];};
}
