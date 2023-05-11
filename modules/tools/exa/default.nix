{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.exa;
in {
  options.khanelinix.tools.exa = with types; {
    enable = mkBoolOpt false "Whether or not to enable exa.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      exa
    ];
  };
}
