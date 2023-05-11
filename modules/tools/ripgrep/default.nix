{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.ripgrep;
in {
  options.khanelinix.tools.ripgrep = with types; {
    enable = mkBoolOpt false "Whether or not to enable ripgrep.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ripgrep
    ];
  };
}
